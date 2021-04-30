terraform {
  backend "remote" {
    organization = "pratik-hc"

    workspaces {
      name = "github-gcp-tf"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.66.0"
    }
  }
}
provider "google" {
  project = "pratik-sandbox"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "vault-network"
}

variable "ssh_pub_key" {
  type = string
}

variable "service_account_email" {
  type = string
}

data "google_compute_image" "disk_image" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2004-lts"
}

resource "google_compute_instance" "vm_instance" {
  name         = "vault-01"
  machine_type = "n1-standard-1"
  boot_disk {
    initialize_params {
      image = data.google_compute_image.disk_image.self_link
    }
  }
  metadata = {
    ssh-keys = var.ssh_pub_key
  }
  network_interface {
    access_config {
    }
    network = google_compute_network.vpc_network.self_link
  }

  allow_stopping_for_update = true

  /* service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  } */

}
