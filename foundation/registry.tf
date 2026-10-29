resource "google_artifact_registry_repository" "frontend_repo" {
  location      = var.gcp_region
  repository_id = var.repo_id
  description   = "Docker registry for the Thursday frontend application"
  format        = "DOCKER"
}
