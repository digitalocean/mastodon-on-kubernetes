# Mastodon Installation

This section will walk you through installing Mastodon on Kubernetes using [Bitnami Mastodon Helm chart.](https://bitnami.com/stack/mastodon/helm)

## Requirements

- [DigitalOcean Infrastructure](../infrastructure/terraform/README.md)
- [doctl CLI](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- [helm](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

## Installation

1. **Retrieve DigitalOcean Managed Postgress Database Credentials**

    Mastodon installation requires to us provide database credentials. Since we have provisioned the Managed Postgres Database on DigitalOcean infrastructure, we can retrieve them via `doctl` or the [cloud control panel.](https://cloud.digitalocean.com/login)
    ```console=
    # List the managed databases on DigitalOcean
    # Copy the <database-id> from the console output
    doctl databases list

    # Retrieve the postgres-password for user-name: doadmin
    doctl databases user get <database-id> <user-name>

    # Copy the postgres-password from the console output
    ```

2. **DigitalOcean Spaces (Static Object Storage) Access**

    We need to create Spaces access keys and the secret to access the [Spaces API](https://docs.digitalocean.com/reference/api/spaces-api/). Follow the *[Creating an Access Key](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key)* section to generate the access key and secret. 

3. **Create the Kubernetes Secrets**

    These secrets are referenced in the [mastodon-bitnami-chart-values.yaml](./mastodon-bitnami-chart-values.yaml) file.

    ```bash=
    # mastodon-creds secret
    # @param postgres-password: DO Managed Postgres Database password 
    # @param AWS_ACCESS_KEY_ID: DO Spaces Access Key
    # @param AWS_SECRET_ACCESS_KEY: DO Spaces Access Secret
    kubectl create ns mastodon && 
    kubectl create -n mastodon secret generic mastodon-creds \
    --from-literal=postgres-password=<insert>  \
    --from-literal=AWS_ACCESS_KEY_ID=<insert>  \
    --from-literal=AWS_SECRET_ACCESS_KEY=<insert>
  
    # mastodon-redis secret
    # @param redis-password: provide any password
    kubectl create -n mastodon secret generic mastodon-redis \
    --from-literal=redis-password=<give any password>

    # lets-encrypt-do-dns secret required for dns01 challenge
    # @param access-token: DO access token 
    kubectl create ns cert-manager && 
    kubectl create -n cert-manager secret generic lets-encrypt-do-dns \
    --from-literal=access-token=<insert DO access token>
    ```
    >**Note**: It is a good practice to use a secret store such as Hashicorp Vault. [Here](https://www.digitalocean.com/community/tutorials/how-to-access-vault-secrets-inside-of-kubernetes-using-external-secrets-operator-eso) is a tutorial to access Vault secrets using [k8s-external-secrets-operator.](https://github.com/external-secrets/external-secrets/)
4. **Bootstrap the Kubernetes Cluster**

    We have leveraged the [hivenetes/k8s-bootstrapper](https://github.com/hivenetes/k8s-bootstrapper) project, which under the hood uses [Argo CD: App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) to install and manage essential applications such as, 
    - [Traefik: HTTP Reverse Proxy and LoadBalancer](https://github.com/traefik/traefik-helm-chart)
    - [Cert-Manager](https://cert-manager.io/)
    - [Metrics-Server](https://github.com/kubernetes-sigs/metrics-server)

    Check out [this doc](../bootstrap/README.md) for more details on the bootstrap process. 
    ```bash
    # Let the bootstrap begin!
    kubectl apply -f https://raw.githubusercontent.com/diabhey/mastodon-blueprint-kubernetes/mastodon-on-do/bootstrap/bootstrap.yaml
    ```
    >**Note:**
    When an Ingress Controller(Traefik) is installed, it creates a service and exposes it as a Load Balancer. When you configure a service as a Load Balancer, DigitalOcean Kubernetes will automatically provision a LoadBalancer in your cloud account.

5. **Configure DNS**

    Once the installation is complete, copy the *EXTERNAL-IP* of the LoadBalancer, as we need this to configure our DNS records.
    ```bash
    # Copy the EXTERNAL_IP of the LoadBalancer
    kubectl get services --namespace traefik traefik --output jsonpath='{.status.loadBalancer.ingress[0].ip}'; echo
    ```
    Head to your domain registrar to configure the DNS as follows:
    - Add an A record for the ***<domain>*** that points to the IP address of the Loadbalancer
    - If you are managing the DNS records via [DigitalOcean DNS](https://docs.digitalocean.com/products/networking/dns/), then you can execute the following command:  
    ```bash
    # Add the LoadBalancer IP to the domain using doctl
    doctl compute domain records create <domain> --record-name mastodon --record-type A --record-data <EXTERNAL-IP>
    # This means that the mastodon instance will be accessed via mastodon.domain
    ```
6. **Install Mastodon via Bitnami Helm chart**
    
    The [mastodon-bitnami-chart-values.yaml](./mastodon-bitnami-chart-values.yaml) file has the chart overrides. Refer to [values.yaml](https://github.com/bitnami/charts/blob/main/bitnami/mastodon/values.yaml) for configuration specifics. 

    ```bash
    MASTODON_HELM_CHART_VERSION="0.1.2"
    
    helm install mastodon bitnami/mastodon \
      --version "$MASTODON_HELM_CHART_VERSION" \
      --namespace mastodon \
      --timeout 10m0s \
      -f "mastodon-bitnami-chart-values.yaml"
    ```

    Once the chart has been successfully installed, you can log in to your mastodon server via the domain used during the installation. 

[**Next steps »**](../observability/README.md)