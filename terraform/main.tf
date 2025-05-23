
module "network" {
  source    = "./modules/network"
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
  token     = var.token

  name = "project_work_network"
}

module "subnetwork" {
  source    = "./modules/subnet"
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
  token     = var.token

  subnet_name    = "project_work_subnetwork"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = module.network.network_id
}

module "security_groups_vm1" {
  source = "./modules/security-groups"
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
  token     = var.token

  network_id          = module.network.network_id
  security_group_name = "sg-vm1"
  ingress_rules = [
    {
      protocol       = "tcp"
      port           = 22
      v4_cidr_blocks = ["0.0.0.0/0"] # Разрешаем SSH-доступ с любого IP
    }
  ]
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

module "vm1" {
  source    = "./modules/instance"
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
  token     = var.token

  name          = "vm1"
  platform_id   = "standard-v3" # Intel Ice Lake
  zone          = "ru-central1-a"
  cores         = 2
  memory        = 2
  core_fraction = 100
  image_id      = data.yandex_compute_image.ubuntu.id
  disk_size     = 20
  disk_type     = "network-ssd"
  subnet_id     = module.subnetwork.subnet_id
  security_group_ids = [module.security_groups_vm1.security_group_id]
  ssh_key_path  = "~/.ssh/terraform_20250320.pub"
  metadata = {
    ssh-keys  = "ubuntu:${file(var.ssh_key_path)}"
  }

  labels = {
  environment = "app-dev"
  terraform   = "true"
  role        = "web"
  }
}



