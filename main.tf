terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}

provider "vsphere" {
  user                 = "i509493@fhict.local" 
  password             = ""
  vsphere_server       = "vcenter.netlab.fontysict.nl"
  allow_unverified_ssl = true
}

variable "datacenter" {
  default = "Netlab-DC"
}

variable "cluster" {
  default = "Netlab-Cluster-B"
}

variable "network" {
  default = "0154_Internet-Static-192.168.154.0_24"
}

variable "datastore" {
  default = "NIM01-1"
}

variable "resource_pool" {
  default = "I509493"
}

variable "num_webservers" {
  default = 2
}

variable "webserver_ips" {
  default = ["192.168.154.36", "192.168.154.37"]
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "Webserver Template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "webserver" {
  count            = var.num_webservers  # Zorgt ervoor dat meerdere servers worden gedeployed
  name             = "webserver-${count.index + 1}"
  resource_pool_id = data.vsphere_resource_pool.resource_pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "_Courses/I3-DB01/I509493"  # Verwijst naar de folder die we hierboven hebben gemaakt

  num_cpus = 2
  memory   = 4096
  guest_id = "ubuntu64Guest"

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = 32  # Minimaal gelijk aan de template
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "webserver-${count.index + 1}"
        domain    = "local"
      }

      network_interface {
        ipv4_address = var.webserver_ips[count.index]
        ipv4_netmask = 24
      }

      ipv4_gateway = "192.168.154.1"
    }
  }
}
