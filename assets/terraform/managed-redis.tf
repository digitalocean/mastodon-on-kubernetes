resource "digitalocean_database_cluster" "mastodon_redis" {
  count           = var.enable_external_redis ? 1 : 0
  name            = var.redis_cluster_name
  engine          = "redis"
  version         = var.redis_cluster_version
  size            = var.redis_cluster_size
  region          = var.redis_cluster_region
  node_count      = var.redis_cluster_node_count
  eviction_policy = "allkeys_lru"
}

resource "digitalocean_database_firewall" "mastodon_redis" {
  count      = var.enable_external_redis ? 1 : 0
  cluster_id = digitalocean_database_cluster.mastodon_redis[0].id
  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.mastodon.id
  }
}
