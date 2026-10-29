data "google_compute_network" "gke_vpc" {
  name = "gke-vpc"
}

data "google_compute_subnetwork" "gke_subnet" {
  name   = "gke-subnet"
  region = var.gcp_region
}
