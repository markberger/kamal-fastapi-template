output "droplet_ip" {
  description = "The public IP address of the DigitalOcean Droplet"
  value       = digitalocean_droplet.droplet.ipv4_address
}

output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_public_key_path" {
  description = "Path to the generated SSH public key"
  value       = local_file.public_key.filename
}

output "ssh_config_path" {
  description = "Path to the SSH config entry file"
  value       = local_file.ssh_config.filename
}

output "ssh_connection_command" {
  description = "Command to connect to the droplet (after adding SSH config)"
  value       = "ssh ${var.app_name}  # This will connect as user 'app'"
}

output "ssh_config_instructions" {
  description = "Instructions for SSH config"
  value       = "Ensure you have 'Include ~/.ssh/config.d/*' in your ~/.ssh/config file"
}

# Spaces bucket outputs
output "spaces_bucket_name" {
  description = "Name of the DigitalOcean Spaces bucket"
  value       = digitalocean_spaces_bucket.backup_bucket.name
}

output "spaces_bucket_endpoint" {
  description = "Endpoint URL for the DigitalOcean Spaces bucket"
  value       = digitalocean_spaces_bucket.backup_bucket.bucket_domain_name
}

output "spaces_access_key" {
  description = "Access key for the DigitalOcean Spaces bucket"
  value       = digitalocean_spaces_key.backup_key.access_key
  sensitive   = true
}

output "spaces_secret_key" {
  description = "Secret key for the DigitalOcean Spaces bucket"
  value       = digitalocean_spaces_key.backup_key.secret_key
  sensitive   = true
}

output "spaces_bucket_policy_applied" {
  description = "Indicates that a policy has been applied to the bucket granting read/write access (excluding delete) to the backup key"
  value       = "Policy applied: Read/Write access (excluding delete operations) for ${digitalocean_spaces_bucket.backup_bucket.name}"
}

output "security_updates_configured" {
  description = "Indicates that automatic security updates have been configured on the server"
  value       = "Automatic security updates configured using unattended-upgrades package with daily checks and automatic installation of security patches"
}

output "swap_configured" {
  description = "Indicates that swap has been configured on the server"
  value       = "Swap file of ${var.swap_size_mb}MB configured with optimized swappiness and cache pressure settings"
}

output "log_rotation_configured" {
  description = "Indicates that log rotation has been configured on the server"
  value       = "Log rotation configured for system logs and Docker logs to prevent disk space issues"
}
