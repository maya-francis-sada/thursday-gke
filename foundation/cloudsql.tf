# 02-repo-infra/cloud_sql.tf

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "google-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.gke_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.gke_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

module "mysql_instance" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "~> 22.0"

  name             = "thursday-sql-instance"
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
    allocated_ip_range  = google_compute_global_address.private_ip_alloc.name
    require_ssl         = false
    authorized_networks = []
  }

  db_name = var.db_name

  user_name     = var.db_user
  user_password = random_password.db_password.result
}
