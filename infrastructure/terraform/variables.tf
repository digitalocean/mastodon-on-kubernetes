# ===================== DO CONFIG VARS =======================
variable "do_token" {
  description = "Personal Access Token to access the DigtialOcean API)"
}

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
  type = map(any)
  default = {
    name       = "mastodon-default"
    node_count = 2
    size       = "s-2vcpu-4gb"
  }
  description = "DOKS cluster default node pool configuration"
}

variable "doks_additional_node_pools" {
  type        = map(any)
  default     = {}
  description = "DOKS cluster extra node pool configuration"
}

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

# ====================== EXTERNAL ELASTICSEARCH CONFIG VARS ======================

variable "enable_external_elasticsearch" {
  type        = bool
  default     = false
  description = "Enable external Elasticsearch cluster (self managed)"
}

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
  default     = ""
  description = "Mastodon DO Spaces S3 bucket access key id"
}

variable "s3_bucket_access_key_secret" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Mastodon DO Spaces S3 bucket access key secret"
}

# ===================== ARGOCD HELM CONFIG VARS =======================

variable "enable_argocd_helm_release" {
  type        = bool
  default     = true
  description = "Enable/disable ArgoCD Helm chart deployment on DOKS"
}

variable "argocd_helm_repo" {
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
  description = "ArgoCD Helm chart repository URL"
}

variable "argocd_helm_chart" {
  type        = string
  default     = "argo-cd"
  description = "argocd Helm chart name"
}

variable "argocd_helm_release_name" {
  type        = string
  default     = "argocd"
  description = "argocd Helm release name"
}

variable "argocd_helm_chart_version" {
  type        = string
  default     = "5.16.14"
  description = "ArgoCD Helm chart version to deploy"
}
variable "argocd_helm_chart_timeout_seconds" {
  type        = number
  default     = 300
  description = "Timeout value for Helm chart install/upgrade operations"
}

variable "argocd_k8s_namespace" {
  type        = string
  default     = "argocd"
  description = "Kubernetes namespace to use for the argocd Helm release"
}

variable "argocd_additional_helm_values_file" {
  type        = string
  default     = "argocd-ha-helm-values.yaml"
  description = "Additional Helm values to use"
}
