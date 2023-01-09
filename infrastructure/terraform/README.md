# Mastodon Infrastructure Automation via Terraform

## Overview

This section will use [Terraform](https://www.terraform.io/) to provision the DigitalOcean infrastructure to run Mastodon.

The Terraform code provided in this repository provisions the following:

-  DigitalOcean Kubernetes cluster [digitalocean-kubernetes.tf](./digitalocean-kubernetes.tf)
-  DigitalOcean-managed PostgreSQL cluster via [digitalocean-managed-postgres.tf](./digitalocean-managed-postgres.tf)
- DigitalOcean Spaces bucket via [digitalocean-s3.tf](./digitalocean-s3.tf)
- Input variables and main module behavior is controlled via [variables.tf](./variables.tf)
- Install and configure [Argo CD](https://argo-cd.readthedocs.io/en/stable/) via [argo-helm-config](./argocd-helm-config.tf)

All essential aspects are configured via Terraform input variables. In addition, a [mastodon.tfvars.sample](./mastodon.tfvars.sample) file is provided to get you started quickly.

## Requirements

The only requirement is [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) installed on your machine and at least some basic knowledge about the tool and main concepts. In addition, it is mandatory to have your DigitalOcean access token.

## Using Terraform to Provision Mastodon Infrastructure

Follow the below steps to get started:

1. Clone this repo and change the directory to `infrastructure/terraform`
2. Initialize Terraform backend:

    ```shell
    terraform init
    ```

3. Copy and rename the `mastodon.tfvars.sample` file to `mastodon.tfvars`:

    ```shell
    cp mastodon.tfvars.sample mastodon.tfvars
    ```

4. Open the `mastodon.tfvars` file and adjust settings according to your needs using a text editor of your choice (preferably with [HCL](https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md) lint support).
5. Use `terraform plan` to inspect infra changes before applying:

    ```shell
    terraform plan -var-file=mastodon.tfvars -out tf-mastodon.out
    ```

6. If you're happy with the changes, issue `terraform apply`:

    ```console
    terraform apply "tf-mastodon.out"
    ```

If everything goes as planned, you should be able to see all infrastructure components provisioned and configured as stated in the `mastodon.tfvars` input configuration file.
