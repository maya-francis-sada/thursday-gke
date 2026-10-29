# 1. Dedicated Namespace for Thursday App
resource "kubernetes_namespace" "thursday_ns" {
  metadata {
    name = "thursday-app"
    labels = {
      "app-routing" = var.app_routing_label
    }
  }
}

resource "kubernetes_deployment" "thursday_app" {
  metadata {
    name      = "thursday-app"
    namespace = kubernetes_namespace.thursday_ns.metadata[0].name
    labels = {
      app = "thursday-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "thursday-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "thursday-app"
        }
      }

      spec {
        container {
          name  = "thursday-app"
          image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_prj_id}/thursday-app-repo/thursday-app:${var.image_tag}"

          port {
            container_port = 8080
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.cloudsql_credentials.metadata[0].name
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "thursday_service" {
  metadata {
    name      = "thursday-service"
    namespace = kubernetes_namespace.thursday_ns.metadata[0].name
    annotations = {
      "cloud.google.com/neg" = jsonencode({ ingress = true })
    }
  }

  spec {
    selector = {
      app = "thursday-app"
    }

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
