resource "kubernetes_manifest" "thursday_httproute" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "thursday-httproute"
      namespace = kubernetes_namespace.thursday_ns.metadata[0].name
    }
    spec = {
      # Attach to the shared Gateway in gateway-infra (from Repo 1)
      parentRefs = [
        {
          group     = "gateway.networking.k8s.io"
          kind      = "Gateway"
          name      = "internal-http-gateway"
          namespace = "gateway-infra"
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/thursday"
              }
            }
          ]
          backendRefs = [
            {
              name = kubernetes_service.thursday_service.metadata[0].name
              port = 8080
            }
          ]
        }
      ]
    }
  }
}
