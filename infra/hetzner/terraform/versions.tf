terraform {
  required_version = ">= 1.6"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52"
    }
    # Hetzner Object Storage is S3 compatible but has no hcloud resource for
    # buckets; Hetzner documents the MinIO provider for bucket management.
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.3"
    }
  }

  # State holds no secrets beyond what the variables carry, but keep it off
  # laptops: configure a remote backend before the first apply, e.g.
  #   terraform init -backend-config=backend.hcl
  # with an S3 backend on a separate Object Storage bucket (see README.md).
  backend "s3" {}
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "minio" {
  minio_server   = "${var.object_storage_location}.your-objectstorage.com"
  minio_region   = var.object_storage_location
  minio_user     = var.object_storage_access_key
  minio_password = var.object_storage_secret_key
  minio_ssl      = true
}
