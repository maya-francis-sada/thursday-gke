data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = "wordpress-maya-state-bucket"
    prefix = "foundation"
  }
}

data "google_container_cluster" "primary" {
  name     = "wordpress-gke-cluster"
  location = var.gcp_region
}
