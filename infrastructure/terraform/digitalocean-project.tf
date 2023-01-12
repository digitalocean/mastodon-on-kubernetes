resource "digitalocean_project" "playground" {
  name        = "mastodon-on-do"
  description = "A project to run Mastodon on DigitalOcean."
  purpose     = "Web Application"
  environment = "Production"
  resources = [digitalocean_kubernetes_cluster.mastodon.urn, digitalocean_database_cluster.mastodon_pg[0].urn,
  digitalocean_spaces_bucket.mastodon_spaces[0].urn]
}