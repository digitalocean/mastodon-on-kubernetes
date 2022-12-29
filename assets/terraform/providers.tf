terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.25.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
  }
}

locals {
  doks_config                 = digitalocean_kubernetes_cluster.mastodon.kube_config[0].raw_config
  doks_endpoint               = digitalocean_kubernetes_cluster.mastodon.endpoint
  doks_token                  = digitalocean_kubernetes_cluster.mastodon.kube_config[0].token
  doks_ca_certificate         = digitalocean_kubernetes_cluster.mastodon.kube_config[0].cluster_ca_certificate
}

provider "digitalocean" {
  # Provider is configured using environment variables:
  # DIGITALOCEAN_TOKEN
  # SPACES_ACCESS_KEY_ID
  # SPACES_SECRET_ACCESS_KEY
}

provider "kubernetes" {
  host  = local.doks_endpoint
  token = local.doks_token
  cluster_ca_certificate = base64decode(
    local.doks_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = local.doks_endpoint
    token = local.doks_token
    cluster_ca_certificate = base64decode(
      local.doks_ca_certificate
    )
  }
}
