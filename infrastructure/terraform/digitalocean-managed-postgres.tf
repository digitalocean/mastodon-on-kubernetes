resource "digitalocean_database_cluster" "mastodon_pg" {
  count      = var.enable_external_postgresql ? 1 : 0
  name       = var.pg_cluster_name
  engine     = "pg"
  version    = var.pg_cluster_version
  size       = var.pg_cluster_size
  region     = var.pg_cluster_region
  node_count = var.pg_cluster_node_count
}

resource "digitalocean_database_db" "mastodon_pg_db" {
  count      = var.enable_external_postgresql ? 1 : 0
  cluster_id = digitalocean_database_cluster.mastodon_pg[0].id
  name       = var.pg_cluster_db_name
}

resource "digitalocean_database_user" "mastodon_pg_user" {
  count      = var.enable_external_postgresql ? 1 : 0
  cluster_id = digitalocean_database_cluster.mastodon_pg[0].id
  name       = var.pg_cluster_db_user
}

resource "digitalocean_database_connection_pool" "mastodon_pg_connection_pool" {
  count      = var.enable_external_postgresql ? 1 : 0
  cluster_id = digitalocean_database_cluster.mastodon_pg[0].id
  name       = "${var.pg_cluster_db_name}-pool"
  mode       = "transaction"
  size       = var.pg_cluster_connection_pool_size
  db_name    = var.pg_cluster_db_name
  user       = var.pg_cluster_db_user
}

resource "digitalocean_database_firewall" "mastodon_pg_firewall" {
  count      = var.enable_external_postgresql ? 1 : 0
  cluster_id = digitalocean_database_cluster.mastodon_pg[0].id
  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.mastodon.id
  }
}
