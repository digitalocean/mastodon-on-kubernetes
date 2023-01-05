locals {
  external_pg_connection_pool = var.enable_external_postgresql ? digitalocean_database_connection_pool.mastodon_pg_connection_pool : []
  external_redis_cluster      = var.enable_external_redis ? digitalocean_database_cluster.mastodon_redis : []
  external_s3_bucket          = var.enable_external_s3 ? digitalocean_spaces_bucket.mastodon_spaces : []
}

resource "helm_release" "mastodon" {
  count            = var.enable_mastodon_helm_release ? 1 : 0
  name             = var.mastodon_helm_release_name
  namespace        = var.mastodon_k8s_namespace
  repository       = var.mastodon_helm_repo
  chart            = var.mastodon_helm_chart
  version          = var.mastodon_helm_chart_version
  timeout          = var.mastodon_helm_chart_timeout_seconds
  create_namespace = true

  # Enable S3 storage support by default
  set {
    name  = "enableS3"
    value = true
  }

  # Enable/disable built-in S3 storage support (Minio) based on input configuration
  set {
    name  = "minio.enabled"
    value = !var.enable_external_s3
  }

  # Enable/disable built-in Elasticsearch support based on input configuration
  set {
    name  = "elasticsearch.enabled"
    value = !var.enable_external_elasticsearch
  }

  # Enable/disable built-in PostgreSQL support based on input configuration
  set {
    name  = "postgresql.enabled"
    value = !var.enable_external_postgresql
  }

  # Enable/disable built-in Redis support based on input configuration
  set {
    name  = "redis.enabled"
    value = !var.enable_external_redis
  }

  # ============= External PostgreSQL configuration (DO managed) =============

  dynamic "set" {
    for_each = local.external_pg_connection_pool
    iterator = pg_connection_pool
    content {
      name  = "externalDatabase.host"
      value = pg_connection_pool.value["private_host"]
    }
  }

  dynamic "set" {
    for_each = local.external_pg_connection_pool
    iterator = pg_connection_pool
    content {
      name  = "externalDatabase.port"
      value = pg_connection_pool.value["port"]
    }
  }

  dynamic "set" {
    for_each = local.external_pg_connection_pool
    iterator = pg_connection_pool
    content {
      name  = "externalDatabase.database"
      value = pg_connection_pool.value["name"]
    }
  }

  dynamic "set_sensitive" {
    for_each = local.external_pg_connection_pool
    iterator = pg_connection_pool
    content {
      name  = "externalDatabase.user"
      value = pg_connection_pool.value["user"]
    }
  }

  dynamic "set_sensitive" {
    for_each = local.external_pg_connection_pool
    iterator = pg_connection_pool
    content {
      name  = "externalDatabase.password"
      value = pg_connection_pool.value["password"]
    }
  }

  # ============= External Redis configuration (DO managed) =============

  dynamic "set" {
    for_each = local.external_redis_cluster
    iterator = redis_cluster
    content {
      name  = "externalRedis.host"
      value = redis_cluster.value["private_host"]
    }

  }

  dynamic "set" {
    for_each = local.external_redis_cluster
    iterator = redis_cluster
    content {
      name  = "externalRedis.port"
      value = redis_cluster.value["port"]
    }
  }

  dynamic "set_sensitive" {
    for_each = local.external_redis_cluster
    iterator = redis_cluster
    content {
      name  = "externalRedis.password"
      value = redis_cluster.value["password"]
    }
  }

  # ============= External S3 configuration (DO managed) =============

  dynamic "set" {
    for_each = local.external_s3_bucket
    content {
      name  = "externalS3.bucket"
      value = var.s3_bucket_name
    }
  }

  dynamic "set" {
    for_each = local.external_s3_bucket
    content {
      name  = "externalS3.region"
      value = var.s3_bucket_region
    }
  }

  dynamic "set" {
    for_each = local.external_s3_bucket
    iterator = do_spaces
    content {
      name  = "externalS3.host"
      value = do_spaces.value["endpoint"]
    }
  }

  dynamic "set_sensitive" {
    for_each = local.external_s3_bucket
    content {
      name  = "externalS3.accessKeyID"
      value = var.s3_bucket_access_key_id
    }
  }

  dynamic "set_sensitive" {
    for_each = local.external_s3_bucket
    content {
      name  = "externalS3.accessKeySecret"
      value = var.s3_bucket_access_key_secret
    }
  }

  # ============= Elasticsearch configuration =============

  set {
    name  = "enableSearches"
    value = true
  }

  # ============= Web component configuration =============

  set {
    name  = "webDomain"
    value = var.mastodon_web_domain
  }

  set {
    name  = "web.nodeAffinityPreset.type"
    value = "soft"
  }

  set {
    name  = "web.nodeAffinityPreset.key"
    value = "doks.digitalocean.com/node-pool"
  }

  set {
    name  = "web.nodeAffinityPreset.values[0]"
    value = var.mastodon_web_component_node_affinity_label
  }

  # ============= Streaming component configuration =============

  set {
    name  = "streaming.nodeAffinityPreset.type"
    value = "soft"
  }

  set {
    name  = "streaming.nodeAffinityPreset.key"
    value = "doks.digitalocean.com/node-pool"
  }

  set {
    name  = "streaming.nodeAffinityPreset.values[0]"
    value = var.mastodon_streaming_component_node_affinity_label
  }

  # ============= Sidekiq component configuration =============

  set {
    name  = "sidekiq.nodeAffinityPreset.type"
    value = "soft"
  }

  set {
    name  = "sidekiq.nodeAffinityPreset.key"
    value = "doks.digitalocean.com/node-pool"
  }

  set {
    name  = "sidekiq.nodeAffinityPreset.values[0]"
    value = var.mastodon_sidekiq_component_node_affinity_label
  }

  # Additional Helm values

  values = [
    file(var.mastodon_additional_helm_values_file)
  ]
}
