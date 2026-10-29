variable "gcp_prj_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "Default region"
}

variable "gcp_zone" {
  type        = string
  description = "Default zone"
}

variable "enable_cdn" {
  type        = bool
  description = "Whether CDN is enabled for the external LB"
}

variable "db_user" {
  type        = string
  description = "Name of the user created within the DB"
}

variable "db_name" {
  type        = string
  description = "Name of the DB created"
}

variable "sql_name" {
  type        = string
  description = "Name of the Cloud SQL resource created"
}

variable "sql_tier" {
  type        = string
  description = "SQL tier"
}

variable "disk_size" {
  type        = number
  description = "Disk size for the SQL instance"
}

variable "availability_type" {
  type        = string
  description = "Availability type of SQL instance"
}

variable "allocated_ip_range" {
  type        = string
  description = "Name of allocated IP range"
}

variable "repo_id" {
  type        = string
  description = "Name of the repository created in Artifact Registry"
}

variable "secret_id" {
  type        = string
  description = "Name of the secret created within the Key Management service"
}
