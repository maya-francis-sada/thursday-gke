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

variable "app_routing_label" {
  description = "Value for the app-routing label on the namespace used by the Gateway selector"
  type        = string
}

variable "image_tag" {
  description = "Tag for the Docker image"
  type        = string
}

variable "thursday_namespace" {
  description = "The Kubernetes namespace name for the thursday application"
  type        = string
}

variable "thursday_dep" {
  description = "The Kubernetes deployment name for the thursday application"
  type        = string
}

variable "kb_secret_name" {
  type        = string
  description = "Name of Kubernetes secret for SQL credentials"
}

variable "db_name" {
  description = "Name of the MySQL database to create and connect to for WordPress"
  type        = string
}

variable "db_user" {
  description = "Username for the WordPress database user in MySQL"
  type        = string
}

variable "route_name" {
  description = "Name of the HTTPRoute created"
  type        = string
}
