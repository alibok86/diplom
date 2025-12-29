variable "cloud_id" {}
variable "folder_id" {}
variable "yc_token" {}
variable "zone" {}
variable "bucket_name" {}
variable "dockerhub_username" {
  type = string
}
variable "dockerhub_password" {
  type      = string
  sensitive = true
}
variable "image_name" {
  default = "test-nginx-app"
}
