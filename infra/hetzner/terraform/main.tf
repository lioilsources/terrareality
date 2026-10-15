# TerraReality production on Hetzner Cloud: two VMs on a private network.
#   app: caddy, web, api, worker, vision, centrifugo, temporal, imgproxy (+ observability)
#   db:  PostgreSQL 17 + PostGIS + pgvector with pgBackRest (WAL to Object Storage)
# Nothing here holds or forwards money (ADR 0002).

locals {
  labels = {
    project = "terrareality"
    env     = "prod"
  }
}

resource "hcloud_ssh_key" "admin" {
  count      = length(var.admin_ssh_public_keys)
  name       = "${var.name_prefix}-admin-${count.index}"
  public_key = var.admin_ssh_public_keys[count.index]
  labels     = local.labels
}

# --- Private network -------------------------------------------------------

resource "hcloud_network" "main" {
  name              = "${var.name_prefix}-net"
  ip_range          = var.network_cidr
  delete_protection = var.delete_protection
  labels            = local.labels
}

resource "hcloud_network_subnet" "servers" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_cidr
}

# --- Firewalls ---------------------------------------------------------------
# Hetzner firewalls filter public interfaces only; private network traffic is
# not affected. The DB server therefore has no public inbound rule except SSH
# from the admin CIDRs, and PostgreSQL binds to its private IP only.

resource "hcloud_firewall" "app" {
  name   = "${var.name_prefix}-app"
  labels = local.labels

  rule {
    description = "HTTP (ACME + redirect to HTTPS)"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "HTTP/3"
    direction   = "in"
    protocol    = "udp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "WireGuard tunnel to the DGX Spark (LLM gateway)"
    direction   = "in"
    protocol    = "udp"
    port        = "51820"
    source_ips  = var.wireguard_peer_cidrs
  }

  rule {
    description = "SSH from admin networks"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.admin_cidrs
  }

  rule {
    description = "ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "db" {
  name   = "${var.name_prefix}-db"
  labels = local.labels

  rule {
    description = "SSH from admin networks"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.admin_cidrs
  }

  rule {
    description = "ICMP from admin networks"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = var.admin_cidrs
  }
}

# --- Volumes -----------------------------------------------------------------

resource "hcloud_volume" "app" {
  name              = "${var.name_prefix}-app-data"
  size              = var.app_volume_size
  location          = var.location
  format            = "ext4"
  delete_protection = var.delete_protection
  labels            = local.labels
}

resource "hcloud_volume" "db" {
  name              = "${var.name_prefix}-db-data"
  size              = var.db_volume_size
  location          = var.location
  format            = "ext4"
  delete_protection = var.delete_protection
  labels            = local.labels
}

# --- Servers -----------------------------------------------------------------

resource "hcloud_server" "app" {
  name                     = "${var.name_prefix}-app"
  server_type              = var.app_server_type
  image                    = var.server_image
  location                 = var.location
  ssh_keys                 = hcloud_ssh_key.admin[*].id
  firewall_ids             = [hcloud_firewall.app.id]
  backups                  = var.server_backups
  delete_protection        = var.delete_protection
  rebuild_protection       = var.delete_protection
  labels                   = merge(local.labels, { role = "app" })
  shutdown_before_deletion = true

  user_data = templatefile("${path.module}/cloud-init/app.yaml.tftpl", {
    ssh_keys   = var.admin_ssh_public_keys
    volume_id  = hcloud_volume.app.id
    mount_path = "/srv"
  })

  network {
    network_id = hcloud_network.main.id
    ip         = var.app_private_ip
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  depends_on = [hcloud_network_subnet.servers]

  lifecycle {
    # cloud-init runs once; edits to the template must not recreate the server.
    ignore_changes = [user_data, ssh_keys, image]
  }
}

resource "hcloud_server" "db" {
  name                     = "${var.name_prefix}-db"
  server_type              = var.db_server_type
  image                    = var.server_image
  location                 = var.location
  ssh_keys                 = hcloud_ssh_key.admin[*].id
  firewall_ids             = [hcloud_firewall.db.id]
  backups                  = var.server_backups
  delete_protection        = var.delete_protection
  rebuild_protection       = var.delete_protection
  labels                   = merge(local.labels, { role = "db" })
  shutdown_before_deletion = true

  user_data = templatefile("${path.module}/cloud-init/db.yaml.tftpl", {
    ssh_keys   = var.admin_ssh_public_keys
    volume_id  = hcloud_volume.db.id
    mount_path = "/srv"
  })

  network {
    network_id = hcloud_network.main.id
    ip         = var.db_private_ip
  }

  # Public IPv4 is kept for outbound traffic (apt, Docker Hub, Object Storage)
  # and admin SSH; inbound is limited by the firewall above.
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  depends_on = [hcloud_network_subnet.servers]

  lifecycle {
    ignore_changes = [user_data, ssh_keys, image]
  }
}

resource "hcloud_volume_attachment" "app" {
  volume_id = hcloud_volume.app.id
  server_id = hcloud_server.app.id
  automount = false
}

resource "hcloud_volume_attachment" "db" {
  volume_id = hcloud_volume.db.id
  server_id = hcloud_server.db.id
  automount = false
}

resource "hcloud_rdns" "app_v4" {
  server_id  = hcloud_server.app.id
  ip_address = hcloud_server.app.ipv4_address
  dns_ptr    = var.app_rdns
}

# --- Object Storage ------------------------------------------------------------

resource "minio_s3_bucket" "media" {
  bucket         = var.media_bucket
  acl            = "private"
  object_locking = false
}

resource "minio_s3_bucket" "backups" {
  bucket = var.backup_bucket
  acl    = "private"
  # pgBackRest manages retention itself; versioning would only keep expired
  # files around and break its expire logic accounting.
  object_locking = false
}
