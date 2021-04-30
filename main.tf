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
  name = "terraform-network"
}
