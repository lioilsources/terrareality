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

# Separate backup project (review V-16): pgBackRest repository. Its keys exist only on the DB VM,
# so a compromised app VM cannot delete backups (docs/runbooks/backup.md).
provider "minio" {
  alias          = "backup"
  minio_server   = "${var.backup_location}.your-objectstorage.com"
  minio_region   = var.backup_location
  minio_user     = var.backup_access_key
  minio_password = var.backup_secret_key
  minio_ssl      = true
}

# Second Object Storage location for the media replica (different failure domain than
# object_storage_location), also in the backup project unless separate keys are given.
provider "minio" {
  alias          = "replica"
  minio_server   = "${var.media_replica_location}.your-objectstorage.com"
  minio_region   = var.media_replica_location
  minio_user     = coalesce(var.media_replica_access_key, var.backup_access_key)
  minio_password = coalesce(var.media_replica_secret_key, var.backup_secret_key)
  minio_ssl      = true
}
