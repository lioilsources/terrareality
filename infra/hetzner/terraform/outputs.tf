output "app_public_ipv4" {
  description = "Point the A records of the app, api, img and site domains here."
  value       = hcloud_server.app.ipv4_address
}

output "app_public_ipv6" {
  description = "AAAA records for the public domains."
  value       = hcloud_server.app.ipv6_address
}

output "db_public_ipv4" {
  description = "Admin SSH only (firewalled)."
  value       = hcloud_server.db.ipv4_address
}

output "app_private_ip" {
  value = var.app_private_ip
}

output "db_private_ip" {
  description = "Host part of DATABASE_URL on the app server; DB_BIND_IP on the DB server."
  value       = var.db_private_ip
}

output "object_storage_endpoint" {
  description = "S3_ENDPOINT / pgBackRest repo1-s3-endpoint."
  value       = "${var.object_storage_location}.your-objectstorage.com"
}

output "media_bucket" {
  value = minio_s3_bucket.media.bucket
}

output "backup_bucket" {
  value = minio_s3_bucket.backups.bucket
}

output "ssh_app" {
  value = "ssh deploy@${hcloud_server.app.ipv4_address}"
}

output "ssh_db" {
  value = "ssh deploy@${hcloud_server.db.ipv4_address}"
}
