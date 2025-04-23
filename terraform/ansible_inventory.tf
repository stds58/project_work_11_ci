locals {
  depends_on = [
    module.vm1
  ]
  inventory_template = templatefile("${path.module}/inventory.tpl", {
    vm1_ip = module.vm1.external_ip_address
  })
}

resource "local_file" "inventory" {
  depends_on = [
    module.vm1
  ]
  content  = local.inventory_template
  filename = "${path.root}/../ansible/inventory"
}

