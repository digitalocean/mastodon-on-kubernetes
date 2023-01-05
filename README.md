# Setting up Mastodon on DOKS

**WORK IN PROGRESS**

**See [Terraform code documentation](./assets/terraform/README.md) for more info on the subject.**

## Introduction

This write up is meant to be a quick start guide for newcomers (and not only) to setup a Mastodon instance running in a DOKS cluster. It starts with a high level overview of Mastodon and all involved components. Then, you will be guided through the initial installation and configuration steps. Finally, you should be able to see your final Mastodon instance alive and kicking and also evaluate its performance under heavy load.

[Mastodon](https://docs.joinmastodon.org) is a microblogging platform similar to Twitter. It lets you create small posts (hence the microblogging terminology), follow people, react to other people posts, etc. Mastodon is an open source and actively developed project, thus it is constantly improved. The main goal is to offer people more freedom and not rely or depend on big tech companies (in contrast with what happened to Twitter lately).

From an architectural point of view, Mastodon is following a descentralized approach compared to Twitter. It means, everyone can run their Mastodon instance all over the world independently, and then interconnect with other instances via federation. This approach gives more freedom because you can operate alone or in small groups, if desired. But, in the end it's all about cooperation and "spreading the word", or empowering the social media all over the globe.

At its heart, the Mastodon stack is powered by the following components:

1. Main backend written in Ruby implementing core logic (uses the Ruby on Rails framework). It also implements the web frontend for all users.
2. A streaming engine implemented using NodeJS used for real time feed updates.
3. Sidekiq jobs used by the main backend to propagate data to other Mastodon instances.
4. An in-memory database (Redis) used for caching and as data storage for Mastodon Sidekiq jobs.
5. A PostgreSQL database used as main storage for all posts and media. This is basically the source of truth for the whole system.
6. An ElasticSearch engine (optionally) used to index and search for posts that you have authored, favorited, or been mentioned in.
7. S3 storage for the rest of persisted data such as media caching.

This guide teaches you how to use Helm to deploy the whole Mastodon stack. A Terraform setup is also provided which you can use by clonning this repository. It is also possible to use this repository as a Terraform module in your custom project as well.

**Important note:**

The Terraform code provided in this repo is meant to be used as a complete solution to provision everything using DigitalOcean as the main cloud provider. It is designed as a 1-click solution, except for the Helm part. Unfortunately, due to some inconsistency in either the Helm provider or the Bitnami packaged chart, the Mastodon Helm installation fails when performed via Terraform. Until a fix is found, the Mastodon Helm release is performed via manual steps.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Step 1 - Provisioning a DOKS cluster](#step-1---provisioning-a-doks-cluster)
- [Step 2 - Installing and Configuring Mastodon using Helm](#step-2---installing-and-configuring-mastodon-using-helm)
- [Step 3 - Testing the Mastodon Setup](#step-3---testing-the-mastodon-setup)
- [Step 4 - Performance Considerations](#step-4---performance-considerations)
- [Step 5 - Terraform Automation](#step-5---terraform-automation)
- [Troubleshooting](#troubleshooting)
- [Cleaning Up](#cleaning-up)
- [Summary](#summary)
- [Additional Resources](#additional-resources)

## Prerequisites

To complete this guide you will need:

1. [Helm](https://www.helm.sh) (version 3.x is required), to install the Bitnami Mastodon chart.
2. [Doctl](https://docs.digitalocean.com/reference/doctl/how-to/install) installed and configured to interact with DigitalOcean services.
3. [Kubectl](https://kubernetes.io/docs/tasks/tools) CLI, to interact with Kubernetes clusters. Make sure it is configured to point to your DOKS cluster, as explained [here](https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/).
4. A valid domain available and configured to point to DigitalOcean name servers. More information is available in this [article](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars). DigitalOcean is not a domain registrar, so you will need to purchase the domain from a well known vendor (such as [GoDaddy](https://www.godaddy.com), [Google](https://domains.google), etc).

## Step 1 - Provisioning a DOKS cluster

**Note:**

**You can skip this step if you already have a similar DOKS cluster set up.**

In this step, you will learn how to use the `doctl k8s` command to create a [DigitalOcean Kubernetes](https://docs.digitalocean.com/products/kubernetes) cluster (or **DOKS** for short). For this tutorial you will need a DOKS cluster with **at least 3 worker nodes**.

**Why bother with creating a DOKS cluster by hand if you can use Terraform for the task?**

Maybe you just want to learn more about [doctl](https://docs.digitalocean.com/reference/doctl) and its features. Or, you just want to quickly spin up a a DOKS cluster to test the Mastodon setup without having to learn new tools such as [Terraform](https://www.terraform.io).

If you still want to benefit from Terraform at the end of this tutorial, don't worry. You can import existing resources into Terraform later on as well, and manage cloud resources as a professional.

The following example teaches you how to create a DOKS cluster with **3 worker nodes**, each having a **2cpu/4gb** configuration and auto-scale set between **3** and **4 nodes** max, using doctl CLI. Final cluster cost varies between **$72-$96/month** with **hourly** billing. To choose a different node size, pick one from the following command `doctl k8s options sizes`. Also, region is set to **nyc1** by default (you can pick another region slug via `doctl k8s options regions`).

```shell
doctl k8s cluster create mastodon-cluster \
  --auto-upgrade=false \
  --maintenance-window "saturday=21:00" \
  --node-pool "name=mastodon-main;size=s-2vcpu-4gb;count=2;tag=mastodon-cluster;label=type=basic;auto-scale=true;min-nodes=3;max-nodes=4" \
  --region nyc1
```

The output looks similar to:

```text
Notice: Cluster is provisioning, waiting for cluster to be running
..................................................................
Notice: Cluster created, fetching credentials
Notice: Adding cluster credentials to kubeconfig file found in "/Users/mastodon/.kube/config"
Notice: Setting current-context to mastodon-cluster
...
```

Next, list the available `DOKS` clusters:

```shell
doctl k8s cluster list
```

The output looks similar to:

```text
ID                                      Name                Region    Version        Auto Upgrade    Status     Node Pools
477f3687-f085-4cda-8105-493af9715152    mastodon-cluster    nyc1      1.25.4-do.0    false           running    mastodon-main
```

Finally, list all DOKS cluster worker nodes:

```shell
kubectl get nodes
```

The output looks similar to:

```text
NAME                  STATUS   ROLES    AGE   VERSION
mastodon-main-mph53   Ready    <none>   26h   v1.25.4
mastodon-main-mpivg   Ready    <none>   22h   v1.25.4
mastodon-main-mpivw   Ready    <none>   22h   v1.25.4
```

If everything was set correctly, you should get a list of all the DOKS cluster worker nodes. The `STATUS` column should print `Ready` if all nodes are healthy.

**Hint:**

If for some reason the kubectl context is not set correctly to point to your cluster, issue the following command to fix it:

```shell
doctl kubernetes cluster kubeconfig save <YOUR_CLUSTER_NAME_HERE>
```

Make sure to replace the `<>` placeholders with your DOKS cluster name first.

## Step 2 - Installing and Configuring Mastodon using Helm

[Helm](https://helm.sh/) has become the de facto package manager for Kubernetes, hence it is the first choice for installing and managing applications on DOKS clusters as well. It also provides very good support and tight integration with Terraform via the [Helm provider](https://registry.terraform.io/providers/hashicorp/helm/).

Mastodon is available as a [Helm chart packaged by Bitnami](https://github.com/bitnami/charts/tree/main/bitnami/mastodon). Although an [official repository](https://github.com/mastodon/chart) exists as well, it is not published yet, nor production ready. [Bitnami](https://bitnami.com) is well known for producing good quality packages for open source software that run on any platform. The Bitnami Mastodon helm chart is updated frequently as well to include bug fixes and security patches, hence it is used in this guide.

Because Mastodon has many dependencies under the hood, the Bitnami Helm chart is very well designed in this regard. Each dependency is available as a sub-chart, and can be enabled or disabled via a specific flag in the values file. Below snippet depicts each dependency and how it can be enabled via the designated flag (`redis.enabled` for Redis, `postgresql.enabled` for PostgreSQL, etc), as stated in the main [Mastodon chart definition](https://github.com/bitnami/charts/blob/main/bitnami/mastodon/Chart.yaml) file:

```yaml
dependencies:
  - condition: redis.enabled
    name: redis
    repository: https://charts.bitnami.com/bitnami
    version: 17.x.x
  - condition: postgresql.enabled
    name: postgresql
    repository: https://charts.bitnami.com/bitnami
    version: 12.x.x
  - condition: elasticsearch.enabled
    name: elasticsearch
    repository: https://charts.bitnami.com/bitnami
    version: 19.x.x
  - condition: minio.enabled
    name: minio
    repository: https://charts.bitnami.com/bitnami
    version: 11.x.x
  - condition: apache.enabled
    name: apache
    repository: https://charts.bitnami.com/bitnami
    version: 9.x.x
```

By default, all dependencies are enabled and installed unless you opt for using self managed (or external) services for Redis, PostgreSQL, etc. The Bitnami Mastodon Helm chart offers [extensive configuration options](https://github.com/bitnami/charts/tree/main/bitnami/mastodon/#parameters) which use a very consistent naming convention and are easy to remember.

**Important note:**

The default options are good enough for development or the initial testing of your Mastodon instance. For production ready instances, it is best to use self managed databases, especially for PostgreSQL. DigitalOcean provides good support for managed databases (including Redis and PostgreSQL) at a reasonable price. Also, when using DO managed Postgres, you also have the option to enable connection pooling (via [PgBouncer](https://www.pgbouncer.org)) which drastically improves Mastodon instance performance. In the [Terraform automation section](#step-5---terraform-automation) from this guide, you will learn how to use Terraform to automate and manage external cloud resources for Mastodon, such as [DO Spaces](https://www.digitalocean.com/products/spaces) (S3 like storage), [DO managed PostgreSQL](https://www.digitalocean.com/products/managed-databases-postgresql), and [Redis](https://www.digitalocean.com/products/managed-databases-redis).

Follow below steps to deploy Mastodon on your DOKS cluster via Helm:

1. First, clone the `mastodon-blueprint-kubernetes` repository, and change directory to your local copy:

    ```shell
    git clone https://github.com/digitalocean/mastodon-blueprint-kubernetes.git

    cd mastodon-blueprint-kubernetes
    ```

2. Next, add the `bitnami` Helm repo, and search for the `mastodon` chart:

    ```shell
    helm repo add bitnami https://charts.bitnami.com/bitnami

    helm repo update bitnami

    helm search repo bitnami | grep mastodon/mastodon
    ```

    The output looks similar to the following:

    ```text
    NAME                            CHART VERSION   APP VERSION     DESCRIPTION
    bitnami/mastodon                0.1.2           4.0.2           Mastodon is self-hosted social network server
    ```

    **Note:**

    The chart of interest is `bitnami/mastodon`, which will install Mastodon on the cluster. Please visit the [bitnami/mastodon](https://github.com/bitnami/charts/tree/main/bitnami/mastodon/) page, for more details about this chart.

3. Then, open and inspect the mastodon Helm values file provided in the `mastodon-blueprint-kubernetes` repository using an editor of your choice (preferably with `YAML` lint support). For example, you can use [VS Code](https://code.visualstudio.com):

    ```shell
    MASTODON_HELM_CHART_VERSION="0.1.2"

    code "assets/manifests/mastodon-values-v${MASTODON_HELM_CHART_VERSION}.yaml"
    ```

    **Note:**

    You will find explanations for each setting in the sample Helm values file.

4. Change Helm values according to your needs (also, make sure to replace all `<>` placeholders where applicable).
5. Save the Helm values file, and install Mastodon using Helm CLI (a dedicated `mastodon` namespace is created as well):

    ```shell
    MASTODON_HELM_CHART_VERSION="0.1.2"

    helm install mastodon bitnami/mastodon \
      --version "$MASTODON_HELM_CHART_VERSION" \
      --namespace mastodon \
      --create-namespace \
      --timeout 10m0s \
      -f "assets/manifests/mastodon-values-v${MASTODON_HELM_CHART_VERSION}.yaml"
    ```

    **Note:**

    A specific version for the mastodon Helm chart is used. In this case `0.1.2` is picked which corresponds to Mastodon application version number `4.0.2` (see the output from `Step 2.`). It’s good practice in general to lock on a specific version. This helps to have predictable results and allows versioning control via Git.

After a few minutes or so (can take up to 10 minutes), check the Mastodon Helm release status:

```shell
helm ls mastodon -n mastodon
```

TBD.

## Step 3 - Testing the Mastodon Setup

## Step 4 - Performance Considerations

## Step 5 - Terraform Automation

See [Terraform code documentation](./assets/terraform/README.md) from this repo.

## Troubleshooting

## Cleaning Up

## Summary

## Additional Resources
