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

resource "google_service_account" "vault_sa" {
  account_id   = "sa-vault"
  display_name = "Vault KMS for auto-unseal"
}

# Create a KMS key ring
resource "google_kms_key_ring" "key_ring" {
  name     = "keyring-vault"
  location = "us"
}

# Create a crypto key for the key ring
resource "google_kms_crypto_key" "crypto_key" {
  name            = "vault-unseal-key"
  key_ring        = google_kms_key_ring.key_ring.self_link
  rotation_period = "100000s"
}

# Add the service account to the Keyring
resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = "roles/owner"

  members = [
    "serviceAccount:${google_service_account.vault_sa.email}",
  ]
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

  # Service account with Cloud KMS roles for the Compute Instance
  service_account {
    email  = google_service_account.vault_sa.email
    scopes = ["cloud-platform", "compute-rw", "userinfo-email", "storage-ro"]
  }

}

output "vault_server_instance_id" {
  value = google_compute_instance.vm_instance.self_link
}
