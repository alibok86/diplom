resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    master_ip          = yandex_compute_instance.public_vm1.network_interface[0].nat_ip_address
    master_private_ip  = yandex_compute_instance.public_vm1.network_interface[0].ip_address

    worker1_ip         = yandex_compute_instance.public_vm2.network_interface[0].nat_ip_address
    worker1_private_ip = yandex_compute_instance.public_vm2.network_interface[0].ip_address

    worker2_ip         = yandex_compute_instance.public_vm3.network_interface[0].nat_ip_address
    worker2_private_ip = yandex_compute_instance.public_vm3.network_interface[0].ip_address
  })

  filename = "/home/ubuntu/kubespray/inventory/mycluster/hosts.yaml"
}
