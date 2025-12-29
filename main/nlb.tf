# 1. Создаем целевую группу с 3 машинами
resource "yandex_lb_target_group" "nginx_ingress_tg" {
  name      = "nginx-ingress-target-group"
  region_id = "ru-central1"

  # Повторяем блок target для каждой из 3 машин
  target {
    subnet_id = yandex_vpc_subnet.public_a.id
    address   = yandex_compute_instance.public_vm1.network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.public_b.id
    address   = yandex_compute_instance.public_vm2.network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.public_d.id
    address   = yandex_compute_instance.public_vm3.network_interface.0.ip_address
  }
}

# 2. Создаем сетевой балансировщик (NLB)
resource "yandex_lb_network_load_balancer" "nginx_lb" {
  name = "nginx-ingress-lb"

  # Описание слушателя (внешний порт 80 -> внутренний 30080)
  listener {
    name        = "http-listener"
    port        = 80          # Внешний порт балансировщика
    target_port = 30080       # Порт на ВМ (Ingress Nginx NodePort)
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  # Подключаем целевую группу и настраиваем Health Check
  attached_target_group {
    target_group_id = yandex_lb_target_group.nginx_ingress_tg.id

    healthcheck {
      name                = "tcp-check-30080"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
      
      # Настройка TCP проверки на порту 30080
      tcp_options {
        port = 30080
      }
    }
  }
}

# Вывод внешнего IP балансировщика
output "lb_external_ip" {
  value = [
    for s in yandex_lb_network_load_balancer.nginx_lb.listener : 
    s.external_address_spec[*].address
  ]
}
