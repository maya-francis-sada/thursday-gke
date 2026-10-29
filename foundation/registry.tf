resource "google_artifact_registry_repository" "frontend_repo" {
  location      = var.gcp_region
  repository_id = "thursday-app-repo"
  description   = "Docker registry for the Thursday frontend application"
  format        = "DOCKER"
}
