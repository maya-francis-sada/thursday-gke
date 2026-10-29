resource "kubernetes_secret" "cloudsql_credentials" {
  metadata {
    name      = "cloudsql-db-credentials"
    namespace = kubernetes_namespace.thursday_ns.metadata[0].name
  }

  data = {
    DB_HOST = data.google_sql_database_instance.mysql_instance.private_ip_address
    DB_USER = "appuser"
    DB_PASS = data.google_secret_manager_secret_version.db_password.secret_data
    DB_NAME = "thursday_db"
  }

  type = "Opaque"
}
