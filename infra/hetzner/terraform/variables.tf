# Secrets have no defaults on purpose. Pass them via TF_VAR_* env vars or an
# untracked terraform.tfvars (see terraform.tfvars.example).

variable "hcloud_token" {
  description = "Hetzner Cloud API token (project scoped, read/write)."
  type        = string
  sensitive   = true
}

variable "object_storage_access_key" {
  description = "Hetzner Object Storage access key (created manually in the console; the API cannot create S3 credentials)."
  type        = string
  sensitive   = true
}

variable "object_storage_secret_key" {
  description = "Hetzner Object Storage secret key."
  type        = string
  sensitive   = true
}

variable "admin_ssh_public_keys" {
  description = "SSH public keys allowed to log in as the deploy user (and root during bootstrap)."
  type        = list(string)
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach SSH (22/tcp) on both servers, e.g. the office or a bastion. Never 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && !contains(var.admin_cidrs, "0.0.0.0/0") && !contains(var.admin_cidrs, "::/0")
    error_message = "admin_cidrs must list specific admin networks, not the whole internet."
  }
}

variable "wireguard_peer_cidrs" {
  description = "Source CIDRs allowed to reach WireGuard (51820/udp) on the app server. The Spark sits behind NAT, so this is usually its public egress IP."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "name_prefix" {
  description = "Prefix for every resource name."
  type        = string
  default     = "terra-prod"
}

variable "location" {
  description = "Hetzner Cloud location for servers and volumes."
  type        = string
  default     = "fsn1"
}

variable "network_zone" {
  description = "Network zone matching the location."
  type        = string
  default     = "eu-central"
}

variable "object_storage_location" {
  description = "Object Storage location (fsn1, nbg1, hel1). The endpoint is <location>.your-objectstorage.com."
  type        = string
  default     = "fsn1"
}

variable "server_image" {
  description = "OS image for both servers."
  type        = string
  default     = "ubuntu-24.04"
}

variable "app_server_type" {
  description = "Server type of the app VM (x86: CI builds amd64 images). Check `hcloud server-type list`."
  type        = string
  default     = "cx43"
}

variable "db_server_type" {
  description = "Server type of the database VM."
  type        = string
  default     = "cx33"
}

variable "app_volume_size" {
  description = "GB of block storage on the app VM (Docker data, Caddy certificates, Temporal is on the DB VM)."
  type        = number
  default     = 40
}

variable "db_volume_size" {
  description = "GB of block storage for the PostgreSQL data directory."
  type        = number
  default     = 80
}

variable "network_cidr" {
  description = "Private network range."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet for the servers."
  type        = string
  default     = "10.10.1.0/24"
}

variable "app_private_ip" {
  description = "Private IP of the app VM."
  type        = string
  default     = "10.10.1.10"
}

variable "db_private_ip" {
  description = "Private IP of the DB VM (DATABASE_URL host)."
  type        = string
  default     = "10.10.1.20"
}

variable "media_bucket" {
  description = "Object Storage bucket for listing media (private; served via imgproxy). Bucket names are global."
  type        = string
  default     = "terrareality-media"
}

variable "backup_bucket" {
  description = "Object Storage bucket for the pgBackRest repository (private)."
  type        = string
  default     = "terrareality-pgbackrest"
}

variable "server_backups" {
  description = "Enable Hetzner automated daily server backups (7 kept, +20 % of the server price)."
  type        = bool
  default     = true
}

variable "delete_protection" {
  description = "Protect servers, volumes and the network against accidental deletion."
  type        = bool
  default     = true
}

variable "app_rdns" {
  description = "Reverse DNS name for the app server's IPv4 (mail reputation, TLS debugging)."
  type        = string
  default     = "app.terrareality.cz"
}
