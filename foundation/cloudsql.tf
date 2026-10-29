module "mysql_instance" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "~> 22.0"

  name             = "thursday-maya-sql-instance"
  project_id       = var.gcp_prj_id
  region           = var.gcp_region
  database_version = "MYSQL_8_0"

  tier              = var.sql_tier
  disk_size         = 10
  disk_type         = "PD_SSD"
  availability_type = "ZONAL"

  ip_configuration = {
    ipv4_enabled        = false
    private_network     = data.google_compute_network.gke_vpc.id
    allocated_ip_range  = "google-services-range-thursday"
    require_ssl         = false
    authorized_networks = []
  }

  db_name = var.db_name

  user_name     = var.db_user
  user_password = random_password.db_password.result
}
