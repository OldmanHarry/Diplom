# --- Сеть ---
resource "yandex_vpc_network" "k8s-network" {
  name = "diplom-network" 
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "k8s-subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# --- Группа Безопасности ---
resource "yandex_vpc_security_group" "k8s-sg" {
  name        = "k8s-main-sg"
  description = "Security group for SSH, K8s, and monitoring"
  network_id  = yandex_vpc_network.k8s-network.id

  # SSH доступ
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Kubernetes API Server
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # HTTP/HTTPS для приложений
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # NodePort диапазон
  ingress {
    protocol       = "TCP"
    description    = "NodePort range"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  # Мониторинг (Grafana, Prometheus)
  ingress {
    protocol       = "TCP"
    description    = "Grafana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  ingress {
    protocol       = "TCP"
    description    = "Prometheus"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9090
  }

  # Внутренний трафик
  ingress {
    protocol          = "ANY"
    description       = "Internal traffic"
    predefined_target = "self_security_group"
  }

  # Исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "All outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Служебный сервер srv ---
resource "yandex_compute_instance" "srv" {
  name        = "srv"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"
  
  resources {
    cores  = 2
    memory = 4
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd805090je9atk2b9jon" # Ubuntu 20.04 LTS
      size     = 30
      type     = "network-hdd"
    }
  }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
  }
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# --- K8s Master ---
resource "yandex_compute_instance" "k8s-master" {
  name        = "k8s-master"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"
  
  resources {
    cores  = 2
    memory = 2
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd805090je9atk2b9jon"
      size     = 20
    }
  }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
  }
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# --- K8s Worker ---
resource "yandex_compute_instance" "k8s-app" {
  name        = "k8s-app"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"
  
  resources {
    cores  = 2
    memory = 2
  }
  
  boot_disk {
    initialize_params {
      image_id = "fd805090je9atk2b9jon"
      size     = 20
    }
  }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s-sg.id]
  }
  
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# --- Outputs ---
output "srv_external_ip" {
  value = yandex_compute_instance.srv.network_interface.0.nat_ip_address
}

output "k8s_master_external_ip" {
  value = yandex_compute_instance.k8s-master.network_interface.0.nat_ip_address
}

output "k8s_app_external_ip" {
  value = yandex_compute_instance.k8s-app.network_interface.0.nat_ip_address
}

output "srv_internal_ip" {
  value = yandex_compute_instance.srv.network_interface.0.ip_address
}

output "k8s_master_internal_ip" {
  value = yandex_compute_instance.k8s-master.network_interface.0.ip_address
}

output "k8s_app_internal_ip" {
  value = yandex_compute_instance.k8s-app.network_interface.0.ip_address
}