resource "google_project_iam_member" "gke_cloudsql_client" {
  project = var.gcp_prj_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_service_account.runner_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "gke_read_db_password" {
  project   = var.gcp_prj_id
  secret_id = google_secret_manager_secret.db_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_service_account.runner_sa.email}"
}
