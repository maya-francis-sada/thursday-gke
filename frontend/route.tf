resource "kubernetes_manifest" "thursday_httproute" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = var.route_name
      namespace = kubernetes_namespace.thursday_ns.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          group       = "gateway.networking.k8s.io"
          kind        = "Gateway"
          name        = "internal-http-gateway"
          namespace   = "gateway-infra"
          sectionName = "https"
        },
        {
          group       = "gateway.networking.k8s.io"
          kind        = "Gateway"
          name        = "external-http-gateway"
          namespace   = "gateway-infra"
          sectionName = "https"
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
