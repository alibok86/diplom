<details>
<summary>1# Дипломный практикум в Yandex.Cloud</summary>
# Дипломный практикум в Yandex.Cloud
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

### Деплой инфраструктуры в terraform pipeline

1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform
---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)


__________________________________________________________________________________________________
</details>

## 1 Задание. 
<details>
<summary>1. Задание - Нажми, чтобы раскрыть</summary>

backend
terraform init -backend-config=backend.tfvars


#### /backend/main.tf
```python
tterraform {
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

```

# Создаём сервисный аккаунт
```python
resource "yandex_iam_service_account" "tf_sa" {
  name        = "tfsa"
  description = "Service account for Terraform operations (least privilege for VPC + Storage)"
  folder_id   = var.folder_id
}
```

# Назначаем роли сервисному аккаунту на уровне папки. Даем роли, необходимые для управления VPC и Storage (минимально для запрашиваемой инфраструктуры)
```python
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
```

# Создаём бакет в Object Storage
```python
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
```

# Генерируем статический access key для сервисного аккаунта (нужен для S3 backend)
```python
resource "yandex_iam_service_account_static_access_key" "tf_sa_key" {
  service_account_id = yandex_iam_service_account.tf_sa.id
  description        = "Static key for Terraform backend access to Object Storage"
}

```

#### /backend/outputs.tf
```python
output "access_key" {
  value     = yandex_iam_service_account_static_access_key.tf_sa_key.access_key
  sensitive = true
}

output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.tf_sa_key.secret_key
  sensitive = true
}

output "bucket_name" {
  value = yandex_storage_bucket.bucket.bucket
}
```

#### /backend/variables.tf
```python
variable "yc_token" {}
variable "cloud_id" {}
variable "folder_id" {}
variable "zone" {default = "ru-central1-a"}
variable "bucket_name" {}
```
</details>


## 2. Задание

<details>
<summary>2. Задание - Нажми, чтобы раскрыть</summary>

Создаю 3ВМ в разных зонах

```python
# PUBLIC VM (with public IP)

resource "yandex_compute_instance" "public_vm1" {
  name        = "public-vm1"
  platform_id = "standard-v2"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd89nl7rpq3plgh1dmtu" # Ubuntu
      size     = 8
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
    memory = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd89nl7rpq3plgh1dmtu" # Ubuntu
      size     = 8
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
    memory = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd89nl7rpq3plgh1dmtu" # Ubuntu
      size     = 8
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
```

2. Подготовка Ansible-конфигураций (Kubespray)

Клонирован репозиторий Kubespray:
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray

Создан виртуальный окружение Python (venv) и установлены зависимости:
python3 -m venv ~/kubespray-venv
source ~/kubespray-venv/bin/activate
pip install -r requirements.txt

Подготовлен inventory файл для Ansible с указанием внутреннего IP всех хостов:

```python
all:
  hosts:
    master1:
      ansible_host: <master_ip>
      ip: <internal_master_ip>
    worker1:
      ansible_host: <worker1_ip>
      ip: <internal_worker1_ip>
    worker2:
      ansible_host: <worker2_ip>
      ip: <internal_worker2_ip>
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

Активировано виртуальное окружение и проверена версия Ansible:

```python
source ~/kubespray-venv/bin/activate
ansible --version  # core 2.17.3
```

Установлены необходимые Ansible collections:
```python
ansible-galaxy collection install \
  ansible.posix \
  community.general \
  kubernetes.core \
  ansible.utils
```
![1](https://github.com/alibok86/diplom/blob/main/1.png?raw=true)

Запущен playbook Kubespray для деплоя кластера:
```python
source ~/kubespray-venv/bin/activate
cd ~/kubespray
ansible-playbook -i /home/ubuntu/kubespray/inventory/mycluster/hosts.yaml \
  --become cluster.yml
```

Kubespray автоматически установил:

Копируем из мастер ноды admin.config
```python
ssh -i ~/.ssh/id_ed25519 ubuntu@158.160.119.226 "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```
![2](https://github.com/alibok86/diplom/blob/main/2.png?raw=true)
![3](https://github.com/alibok86/diplom/blob/main/3.png?raw=true)
![4](https://github.com/alibok86/diplom/blob/main/4.png?raw=true)
![5](https://github.com/alibok86/diplom/blob/main/5.png?raw=true)

</details> 

## 3. Задание

<details>
<summary>3. Задание - Нажми, чтобы раскрыть</summary>

#### Создаём простой index.html для nginx:

```python

<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Netology</title>
</head>
<body>
    <h1>Hello, Docker!</h1>
</body>
</html>

```
#### Создаём простой конфиг для nginx:

nginx.conf

```python
events {}

http {
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
```

Вход в DockerHub:

```python
docker login
docker push alibok/test-nginx-app:latest
```
![6](https://github.com/alibok86/diplom/blob/main/6.png?raw=true)

Был создан GIT репозиторий с тестовым nginx
https://github.com/alibok86/nginx-test

Был создан образ для Dockerhub и выгружен test-nginx-app
https://hub.docker.com/repository/docker/alibok/test-nginx-app

</details>



## 4. Задание

<details>
<summary>4. Задание - Нажми, чтобы раскрыть</summary>

#### Создаем Network load blancer

```python
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

```
#### Клонируем репозиторий kube-prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

```python
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.service.type=ClusterIP
```

#### Клонируем репозиторий ingress-nginx

```python
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace monitoring --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443
```
#### Применяем настройки для nginx
```python
kubectl apply -f nginx_svc.yaml -f nginx_depl.yaml -f ingress.yaml
Узнаем админ пароль для Grafana
kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
![8](https://github.com/alibok86/diplom/blob/main/7.png?raw=true)


#### Установка Атлантис
```python
export WEBHOOK_SECRET=$(openssl rand -hex 20)
echo $WEBHOOK_SECRET

Подставляем токен.
kubectl create secret generic atlantis-vcs \
  --from-literal=github_token="" \
  --from-literal=github_secret="$WEBHOOK_SECRET"

kubectl apply -f atlantis_pv.yaml

cd ~/diplom/main/monitoring/
helm install atlantis runatlantis/atlantis -f values.yaml --disable-openapi-validation
``` 

http://62.84.124.167:32313/ Атлатис установлен 
![9](https://github.com/alibok86/diplom/blob/main/9.png?raw=true)

Создаем отдельную ветку и пушим репозиторий

```python
git checkout -b feature/test-atlantis
git add .
git commit -m "Add atlantis config"
git push origin feature/test-atlantis
```
![10](https://github.com/alibok86/diplom/blob/main/10.png?raw=true)
![11](https://github.com/alibok86/diplom/blob/main/11.png?raw=true)

#### Для реализации CI/CD с использованием GitHub Actions добавил Settings > Secrets and variables > Actions 
добавил 
  DOCKER_PASSWORD 
  DOCKER_USERNAME 
  KUBECONFIG

git tag v1.0.0
git push origin v1.0.0

![12](https://github.com/alibok86/diplom/blob/main/12.png?raw=true)