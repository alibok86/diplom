all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519

    kube_network_plugin: calico
    container_manager: containerd

    # SAN для сертификата
    supplementary_addresses_in_ssl_keys:
      - "${master_ip}"
      - "${master_private_ip}"

    # Явно указываем полный адрес API сервера
    kube_apiserver_endpoint: "https://${master_ip}:6443"

  hosts:
    master1:
      ansible_host: "${master_ip}"
      ip: "${master_private_ip}"
      access_ip: "${master_private_ip}"

    worker1:
      ansible_host: "${worker1_ip}"
      ip: "${worker1_private_ip}"
      access_ip: "${worker1_private_ip}"

    worker2:
      ansible_host: "${worker2_ip}"
      ip: "${worker2_private_ip}"
      access_ip: "${worker2_private_ip}"

  children:

    kube_control_plane:
      hosts:
        master1:
      vars:
        kube_external_apiserver_address: "${master_ip}"
        kube_apiserver_cert_extra_sans:
          - "${master_ip}"
          - "${master_private_ip}"

    kube_node:
      hosts:
        worker1:
        worker2:

    etcd:
      hosts:
        master1:

    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
      vars:
        kubeconfig_localhost: false
        # Добавляем эту настройку для правильного формата в kubeconfig
        kube_apiserver_url: "https://{{ kube_external_apiserver_address | default(kube_apiserver_ip) }}:{{ kube_apiserver_port | default(6443) }}"