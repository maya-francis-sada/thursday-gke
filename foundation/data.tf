data "google_container_cluster" "primary" {
  name     = "wordpress-gke-cluster"
  location = var.gcp_region
}

data "google_service_account" "runner_sa" {
  account_id = "github-runner-sa"
}
