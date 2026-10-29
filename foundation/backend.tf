terraform {
  backend "gcs" {
    bucket = "wordpress-maya-state-bucket"
    prefix = "thursday-foundation"
  }
}
