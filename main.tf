terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.48.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket                      = "terraform"
    key                         = "terraform.tfstate"
    workspace_key_prefix        = ""
    region                      = "auto"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
    endpoints = {
      s3 = "https://63540284f50c1886beda4daca5793813.r2.cloudflarestorage.com"
    }
  }
}

variable "environment" {
  description = "Deployment environment. Use dev or prod."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}

variable "hostname" {
  description = "Hetzner server name."
  type        = string
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
}

locals {
  dns_record_name = var.environment == "prod" ? "*" : var.hostname
}

data "cloudflare_zone" "domain" {
  name = "rcastellotti.dev"
}
resource "cloudflare_record" "wildcard_ipv6" {
  zone_id = data.cloudflare_zone.domain.id
  name    = local.dns_record_name
  type    = "AAAA"
  content = hcloud_server.rcastellotti-dev.ipv6_address
  ttl     = 1
  proxied = false
}

resource "hcloud_firewall" "web-firewall" {
  name = "${var.environment}-web-firewall"
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Allow HTTP (caddy)"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Allow HTTPS (caddy)"
  }
}

resource "hcloud_server" "rcastellotti-dev" {
  name        = var.hostname
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = "hel1"
  user_data   = templatefile("${path.module}/cloud-init.yml", { tailscale_authkey = var.tailscale_authkey })
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
}
resource "hcloud_firewall_attachment" "web_fw_attach" {
  firewall_id = hcloud_firewall.web-firewall.id
  server_ids  = [hcloud_server.rcastellotti-dev.id]
}

output "server_ipv6" {
  description = "Primary IPv6 address"
  value       = hcloud_server.rcastellotti-dev.ipv6_address
}
output "hostname" {
  description = "Server hostname"
  value       = hcloud_server.rcastellotti-dev.name
}
