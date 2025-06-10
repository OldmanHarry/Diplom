terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gft7h38p6o500hldoq"
  folder_id = "b1g9gia03e338isbg8d4"
  zone      = "ru-central1-a"
}
