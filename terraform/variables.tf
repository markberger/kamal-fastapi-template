variable "app_name" {
  description = "Name of your application / server"
  type        = string
  default     = "myapp"
}

variable "do_token" {
  description = "DigitalOcean API Token (optional, can use DIGITALOCEAN_TOKEN environment variable instead)"
  type        = string
  sensitive   = true
  default     = null # Default to null, which will cause the provider to use the environment variable
}

variable "region" {
  description = "DigitalOcean region for the droplet"
  type        = string
  default     = "sfo2"
}

variable "droplet_size" {
  description = "Size of the DigitalOcean droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "spaces_bucket_name" {
  description = "Name of the DigitalOcean Spaces bucket for backups, defaults to $${app_name}-backups"
  type        = string
  default     = null
}

variable "spaces_region" {
  description = "DigitalOcean region for Spaces bucket (may differ from droplet region)"
  type        = string
  default     = "sfo2" # Spaces are available in specific regions
}

variable "spaces_access_key" {
  description = "DigitalOcean Spaces access key (optional, can use SPACES_ACCESS_KEY_ID environment variable instead)"
  type        = string
  sensitive   = true
  default     = null # Default to null, which will cause the provider to use the environment variable
}

variable "spaces_secret_key" {
  description = "DigitalOcean Spaces secret key (optional, can use SPACES_SECRET_ACCESS_KEY environment variable instead)"
  type        = string
  sensitive   = true
  default     = null # Default to null, which will cause the provider to use the environment variable
}

variable "swap_size_mb" {
  description = "Size of the swap file in MB"
  type        = number
  default     = 2048 # 2GB swap by default
}
