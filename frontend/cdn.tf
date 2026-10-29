resource "kubernetes_manifest" "enable_cdn" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "GCPBackendPolicy"
    metadata = {
      name      = "thursday-cdn-policy"
      namespace = "thursday-app"
    }
    spec = {
      targetRef = {
        group = ""
        kind  = "Service"
        name  = "thursday-service"
      }
      parameters = {
        apiVersion = "networking.gke.io/v1"
        kind       = "GCPBackendPolicyConfig"
        spec = {
          cdn = {
            enabled = true
          }
        }
      }
    }
  }
}
