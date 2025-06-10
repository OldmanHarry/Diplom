# Создаем служебный сервер 'srv'
resource "yandex_compute_instance" "srv" {
  name        = "srv"
  zone        = "ru-central1-a" 
  platform_id = "standard-v3"   

  resources {
    cores  = 2     # 2 vCPU, как рекомендовано для Elastic Stack 
    memory = 4     # 4 GB RAM, как рекомендовано для Elastic Stack 
    gpus   = 0
  }

  boot_disk {
    initialize_params {
      image_id    = "fd805090je9atk2b9jon"
      size        = 30 
      type        = "network-hdd" 
    }
  }

  network_interface {
    # Создаем новую сеть и подсеть, если их нет
    subnet_id = yandex_vpc_subnet.main.id
    nat       = true # Разрешить публичный IP-адрес для доступа из интернета
  }

  metadata = {
    ssh-keys = "ubuntu:${file("${pathexpand("~")}/.ssh/id_rsa.pub")}"
  }
}

# Создаем VPC сеть
resource "yandex_vpc_network" "main" {
  name = "main-network"
}

# Создаем подсеть в нашей сети
resource "yandex_vpc_subnet" "main" {
  name           = "main-subnet-a"
  zone           = "ru-central1-a" 
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"] 
}

# Вывод публичного IP-адреса сервера 'srv'
output "srv_external_ip" {
  value = yandex_compute_instance.srv.network_interface.0.nat_ip_address
}