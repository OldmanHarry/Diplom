terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0" # Используем актуальную версию
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gft7h38p6o500hldoq"
  folder_id = "b1g3gqt0ani1t6r5kp73"
  zone      = "ru-central1-a"
}