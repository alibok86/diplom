terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.174.0"
    }
        docker = {
      source  = "kreuzwerker/docker"
    }
    dockerhub = {
      source  = "BarnabyShearer/dockerhub"
      version = "~> 0.0.15"
  }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
  }
}

provider "yandex" {
  token      = var.yc_token
  cloud_id   = var.cloud_id
  folder_id  = var.folder_id
  zone       = var.zone
}

# Создаём VPC
resource "yandex_vpc_network" "vpc" {
  name = "my-vpc"
}

# Подсети в разных зонах
resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["192.168.12.0/24"]
}

# PUBLIC VM (with public IP)

resource "yandex_compute_instance" "public_vm1" {
  name        = "public-vm1"
  platform_id = "standard-v2"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd89nl7rpq3plgh1dmtu" # Ubuntu
      size     = 50
      type     = "network-ssd"   
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_a.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
    scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "public_vm2" {
  name        = "public-vm2"
  platform_id = "standard-v2"
  zone = "ru-central1-b"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd89nl7rpq3plgh1dmtu" # Ubuntu
      size     = 50
      type     = "network-ssd"   
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_b.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
    scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "public_vm3" {
  name        = "public-vm3"
  platform_id = "standard-v2"
  zone = "ru-central1-d"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd89nl7rpq3plgh1dmtu" # Ubuntu
      size     = 50
      type     = "network-ssd"   
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_d.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
    scheduling_policy {
    preemptible = true
  }
}


provider "dockerhub" {
  username = var.dockerhub_username
  password = var.dockerhub_password
}

provider "docker" {
  registry_auth {
    address  = "registry-1.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_password
  }
}

# Создание репозитория в DockerHub
resource "dockerhub_repository" "repo" {
  name        = var.image_name
  namespace   = var.dockerhub_username
  description = "Test nginx application created via Terraform"
  private     = false
}


# Сборка Docker image
resource "docker_image" "app" {
  name = "${var.dockerhub_username}/${var.image_name}:latest"

  build {
    context    = "${path.module}/nginx"
    dockerfile = "Dockerfile"
  }
}