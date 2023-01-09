# Mastodon Infrastrucure Automation via Terraform

**WORK IN PROGRESS**

## Overview

Terraform is a very popular tool used for infra tasks automation, and it works on all major cloud providers. DigitalOcean is no exception.

The Terraform code provided in this repository is able to:

1. Provision a DOKS cluster to deploy the Bitnami Mastodon Helm chart via [doks.tf](./doks.tf).
2. Install and configure the Bitnami Mastodon Helm release via [k8s-config.tf](./k8s-config.tf).
3. Install and configure a DO managed PostgreSQL cluster via [managed-postgres.tf](./managed-postgres.tf).
4. Install and configure a DO managed Redis cluster via [managed-redis.tf](./managed-redis.tf).
5. Install and configure a DO Spaces bucket via [s3.tf](./s3.tf).
6. Input variables and main module behavior is controlled via [variables.tf](./variables.tf).

The Terraform code can be used as a module in other projects as well, if desired.

**Important note:**

The Terraform code provided in this repo is meant to be used as a complete solution to provision everything using DigitalOcean as the main cloud provider. It is designed to be a 1-click solution, except for the Helm part. Unfortunately, due to some inconsistency in either the Helm provider or the Bitnami packaged chart, the Mastodon Helm installation fails when performed via Terraform. Until a fix is found, the Mastodon Helm release is performed via manual steps.

All important aspects are configured via Terraform input variables. A [mastodon.tfvars.sample](./mastodon.tfvars.sample) file is provided to get you started quickly.

## Requirements

The only requirement is [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) installed on your machine, and at least some basic knowledge about the tool and main concepts. You also need your DigitalOcean access token at hand.

## Managing DOKS Configuration

Following input variables are available to configure DOKS (each variable purpose is explained in the `description` field):

```json
# ===================== DOKS CONFIG VARS =======================

variable "doks_cluster_name_prefix" {
  type        = string
  default     = "mastodon-k8s"
  description = "DOKS cluster name prefix value (a random suffix is appended automatically)"
}

variable "doks_k8s_version" {
  type        = string
  default     = "1.25"
  description = "DOKS Kubernetes version"
}

variable "doks_cluster_region" {
  type        = string
  default     = "nyc1"
  description = "DOKS region name"
}

variable "doks_default_node_pool" {
  type = map
  default = {
    name       = "mastodon-default"
    node_count = 2
    size       = "s-2vcpu-4gb"
  }
  description = "DOKS cluster default node pool configuration"
}

variable "doks_additional_node_pools" {
  type = map
  default = {}
  description = "DOKS cluster extra node pool configuration"
}
```

## Managing Kubernetes Configuration

Following input variables are available to configure Kubernetes stuff - the Mastodon Helm release (each variable purpose is explained in the `description` field):

```json
# =============== MASTODON CONFIG VARS ==================

variable "enable_mastodon_helm_release" {
  type = bool
  default = true
  description = "Enable/disable Bitnami Mastodon Helm chart deployment on DOKS"
}

variable "mastodon_helm_repo" {
  type        = string
  default     = "https://charts.bitnami.com/bitnami"
  description = "Mastodon Helm chart repository URL"
}

variable "mastodon_helm_chart" {
  type        = string
  default     = "mastodon"
  description = "Mastodon Helm chart name"
}

variable "mastodon_helm_release_name" {
  type        = string
  default     = "mastodon"
  description = "Mastodon Helm release name"
}

variable "mastodon_helm_chart_version" {
  type        = string
  default     = "0.1.2"
  description = "Mastodon Helm chart version to deploy"
}
variable "mastodon_helm_chart_timeout_seconds" {
  type        = number
  default     = 300
  description = "Timeout value for Helm chart install/upgrade operations"
}

variable "mastodon_k8s_namespace" {
  type        = string
  default     = "mastodon"
  description = "Kubernetes namespace to use for the Mastodon Helm release"
}

variable "mastodon_web_component_node_affinity_label" {
  type = string
  default = ""
}

variable "mastodon_streaming_component_node_affinity_label" {
  type = string
  default = ""
}

variable "mastodon_sidekiq_component_node_affinity_label" {
  type = string
  default = ""
}

variable "mastodon_web_domain" {
  type = string
  description = "Sets the domain name for your Mastodon instance (REQUIRED)"
}

variable "mastodon_additional_helm_values_file" {
  type = string
  default = "mastodon-helm-values.yaml"
  description = "Additional Helm values to use"
}
```

## Managing External PostgreSLQ Configuration (DO Managed)

Following input variables are available to configure DO Managed PostgreSQL (each variable purpose is explained in the `description` field):

```json
# =============== EXTERNAL POSTGRES CONFIG VARS (DO MANAGED) =================

variable "enable_external_postgresql" {
  type        = bool
  default     = false
  description = "Enable external PostgreSQL cluster (DO managed)"
}

variable "pg_cluster_name" {
  type        = string
  default     = "pg-mastodon"
  description = "DO managed PostgreSQL cluster name"
}

variable "pg_cluster_version" {
  type        = string
  default     = "14"
  description = "DO managed PostgreSQL engine version"
}

variable "pg_cluster_region" {
  type        = string
  default     = "nyc1"
  description = "DO managed PostgreSQL cluster region"
}

variable "pg_cluster_size" {
  type        = string
  default     = "db-s-1vcpu-1gb"
  description = "DO managed PostgreSQL cluster worker nodes size"
}

variable "pg_cluster_node_count" {
  type        = number
  default     = 1
  description = "DO managed PostgreSQL cluster node count"
}

variable "pg_cluster_db_name" {
  type        = string
  default     = "mastodon"
  description = "DO managed PostgreSQL cluster database name"
}

variable "pg_cluster_db_user" {
  type        = string
  default     = "mastodon"
  description = "DO managed PostgreSQL cluster database user"
}

variable "pg_cluster_connection_pool_size" {
  type        = number
  default     = 20
  description = "PgBouncer connection pool size"
}
```

## Managing External Redis Configuration (DO Managed)

Following input variables are available to configure DO Managed Redis (each variable purpose is explained in the `description` field):

```json
# =============== EXTERNAL REDIS CONFIG VARS (DO MANAGED) =================

variable "enable_external_redis" {
  type        = bool
  default     = false
  description = "Enable external Redis cluster (DO managed)"
}

variable "redis_cluster_name" {
  type        = string
  default     = "redis-mastodon"
  description = "DO managed Redis cluster name"
}

variable "redis_cluster_version" {
  type        = string
  default     = "7"
  description = "DO managed Redis engine version"
}

variable "redis_cluster_region" {
  type        = string
  default     = "nyc1"
  description = "DO managed Redis cluster region"
}

variable "redis_cluster_size" {
  type        = string
  default     = "db-s-1vcpu-1gb"
  description = "DO managed Redis cluster worker nodes size"
}

variable "redis_cluster_node_count" {
  type        = number
  default     = 1
  description = "DO managed Redis cluster node count"
}
```

## Managing External S3 Configuration (DO Managed)

Following input variables are available to configure DO Spaces (each variable purpose is explained in the `description` field):

```json
# ====================== EXTERNAL S3 CONFIG VARS (DO MANAGED) ======================

variable "enable_external_s3" {
  type        = bool
  default     = false
  description = "Enable external S3 for Mastodon persistent data (DO Spaces)"
}

variable "s3_bucket_name" {
  type        = string
  default     = "mastodon-st"
  description = "Mastodon DO Spaces S3 bucket name"
}

variable "s3_bucket_region" {
  type        = string
  default     = "nyc3"
  description = "Mastodon DO Spaces S3 bucket region"
}

variable "s3_bucket_access_key_id" {
  type        = string
  sensitive   = true
  default = ""
  description = "Mastodon DO Spaces S3 bucket access key id"
}

variable "s3_bucket_access_key_secret" {
  type        = string
  sensitive   = true
  default = ""
  description = "Mastodon DO Spaces S3 bucket access key secret"
}
```

## Using Terraform to Provision Mastodon Infrastructure

Follow below steps to get started:

1. Clone this repo and change directory to `assets/terraform`.
2. Initialize Terraform backend:

    ```shell
    terraform init
    ```

3. Copy and rename the `mastodon.tfvars.sample` file to `mastodon.tfvars`:

    ```shell
    cp mastodon.tfvars.sample mastodon.tfvars
    ```

4. Open the `mastodon.tfvars` file and adjust settings according to your needs using a text editor of your choice (prefarrably with [HCL](https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md) lint suppport).
5. Use `terraform plan` to inspect infra changes before applying:

    ```shell
    terraform plan -var-file=mastodon.tfvars -out tf-mastodon.out
    ```

6. If you're happy with the changes, issue `terraform apply`:

    ```console
    terraform apply "tf-mastodon.out"
    ```

If everything goes as planned, you should be able to see all infrastructure components provisioned and configured as stated in the `mastodon.tfvars` input configuration file.

**TBD.**
