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