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
