provider "triton" {}

terraform {
  required_version = ">= 0.11.0"
  backend "manta" {
    path = "tsg-nomad-client"
  }
}

resource "triton_machine" "nomad_client" {
  count            = "${var.nomad_client_count}"
  name             = "${format("tsg-nomad-client-%02d", count.index + 1)}"
  package          = "${var.nomad_instance_package}"
  image            = "${data.triton_image.nomad_client.id}"

  cns {
    services = ["${var.nomad_cns_tag}"]
  }

  tags {
    name = "${format("tsg-nomad-client-%02d", count.index + 1)}"
  }

  affinity    = ["instance!=nomad*"]
  user_script = "${element(
                   data.template_file.user_data.*.rendered,
                   count.index)}"
  networks    = ["${data.triton_network.private.id}"]
}

data "triton_image" "nomad_client" {
  name        = "${var.nomad_image_name}"
  version     = "${var.nomad_version}"
  most_recent = true
}

data "triton_network" "private" {
  name = "Joyent-SDC-Private"
}

data "triton_account" "main" {}

data "triton_datacenter" "current" {}

data "template_file" "user_data" {
  count = "${var.nomad_client_count}"
  template = "${file("instance-user.conf")}"
  vars {
    hostname = "${format("tsg-nomad-client-%02d", count.index + 1)}"
    dc = "${data.triton_datacenter.current.name}"
    nomad_cns_url = "${format("nomadserver.svc.%s.%s.cns.joyent.com", data.triton_account.main.id, data.triton_datacenter.current.name)}"
    consul_cns_url = "${format("%s.svc.%s.%s.cns.joyent.com", var.consul_cns_tag, data.triton_account.main.id, data.triton_datacenter.current.name)}"
  }
}
