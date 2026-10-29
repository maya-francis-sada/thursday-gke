resource "google_project_iam_member" "gke_cloudsql_client" {
  project = var.gcp_prj_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_service_account.runner_sa.email}"
}
