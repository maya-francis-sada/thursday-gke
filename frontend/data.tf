data "google_sql_database_instance" "mysql_instance" {
  name    = "thursday-maya-sql-instance"
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

data "google_secret_manager_secret" "db_password" {
  secret_id = "thursday-db-password"
}

data "google_secret_manager_secret_version" "db_password" {
  secret = data.google_secret_manager_secret.db_secret.id
}
