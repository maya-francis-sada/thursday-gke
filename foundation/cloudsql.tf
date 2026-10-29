module "mysql_instance" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "~> 22.0"

  name             = var.sql_name
  project_id       = var.gcp_prj_id
  region           = var.gcp_region
  database_version = "MYSQL_8_0"

  tier              = var.sql_tier
  disk_size         = var.disk_size
  disk_type         = "PD_SSD"
  availability_type = var.availability_type

  ip_configuration = {
    ipv4_enabled        = false
    private_network     = data.google_compute_network.gke_vpc.id
    allocated_ip_range  = var.allocated_ip_range
    require_ssl         = false
    authorized_networks = []
  }

  db_name = var.db_name

  user_name     = var.db_user
  user_password = random_password.db_password.result
}
