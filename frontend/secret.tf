resource "kubernetes_secret" "cloudsql_credentials" {
  metadata {
    name      = var.kb_secret_name
    namespace = kubernetes_namespace.thursday_ns.metadata[0].name
  }

  data = {
    DB_HOST = data.google_sql_database_instance.mysql_instance.private_ip_address
    DB_USER = var.db_user
    DB_PASS = data.google_secret_manager_secret_version.db_password.secret_data
    DB_NAME = var.db_name
  }

  type = "Opaque"
}
