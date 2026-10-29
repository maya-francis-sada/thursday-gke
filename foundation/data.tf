data "google_container_cluster" "primary" {
  name     = "wordpress-gke-cluster"
  location = var.gcp_region
}

data "google_service_account" "runner_sa" {
  account_id = "github-runner-sa"
}

data "google_compute_network" "gke_vpc" {
  name = "gke-vpc"
}

data "google_compute_subnetwork" "gke_subnet" {
  name   = "gke-subnet"
  region = var.gcp_region
}
