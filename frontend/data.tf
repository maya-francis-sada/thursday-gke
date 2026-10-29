data "google_sql_database_instance" "mysql_instance" {
  name    = "thursday-sql-instance"
  project = var.gcp_prj_id
}

data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = "wordpress-maya-state-bucket"
    prefix = "foundation"
  }
}

data "google_container_cluster" "primary" {
  name    = "wordpress-gke-cluster"
  project = var.gcp_prj_id
}
