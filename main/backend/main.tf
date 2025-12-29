terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.174.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# Создаём сервисный аккаунт
resource "yandex_iam_service_account" "tf_sa" {
  name        = "tfsa"
  description = "Service account for Terraform operations (least privilege for VPC + Storage)"
  folder_id   = var.folder_id
}

# Назначаем роли сервисному аккаунту на уровне папки
# Даем роли, необходимые для управления VPC и Storage (минимально для запрашиваемой инфраструктуры)
resource "yandex_resourcemanager_folder_iam_member" "sa_roles" {
  for_each = toset([
    "compute.editor",
    "vpc.admin",
    "storage.admin"
  ])

  folder_id = var.folder_id
  role      = each.key
  member    = "serviceAccount:${yandex_iam_service_account.tf_sa.id}"
}


# Создаём бакет в Object Storage
resource "yandex_storage_bucket" "bucket" {
  folder_id     = var.folder_id
  bucket        = var.bucket_name
  force_destroy = true
}

resource "yandex_storage_bucket_iam_binding" "public_access" {
  bucket  = yandex_storage_bucket.bucket.bucket
  role    = "storage.viewer"
  members = ["system:allUsers"]
}

# Генерируем статический access key для сервисного аккаунта (нужен для S3 backend)
resource "yandex_iam_service_account_static_access_key" "tf_sa_key" {
  service_account_id = yandex_iam_service_account.tf_sa.id
  description        = "Static key for Terraform backend access to Object Storage"
}