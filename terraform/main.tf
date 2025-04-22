# Configure the DigitalOcean Provider
terraform {
  required_version = "= 1.11.3"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Use the DIGITALOCEAN_TOKEN environment variable for authentication
provider "digitalocean" {
  # The provider will use the DIGITALOCEAN_TOKEN environment variable by default
  # If var.do_token is set, it will override the environment variable
  token = var.do_token

  # Configure Spaces credentials
  # These will use SPACES_ACCESS_KEY_ID and SPACES_SECRET_ACCESS_KEY environment variables by default
  # If var.spaces_access_key and var.spaces_secret_key are set, they will override the environment variables
  spaces_access_id  = var.spaces_access_key
  spaces_secret_key = var.spaces_secret_key
}

# Generate an SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to ~/.ssh directory
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = pathexpand("~/.ssh/${var.app_name}_id_rsa")
  file_permission = "0600"
}

# Save the public key to ~/.ssh directory
resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = pathexpand("~/.ssh/${var.app_name}_id_rsa.pub")
  file_permission = "0644"
}

# Add the SSH key to DigitalOcean
resource "digitalocean_ssh_key" "default" {
  name       = "${var.app_name} SSH Key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Create a DigitalOcean Droplet
resource "digitalocean_droplet" "droplet" {
  image    = "ubuntu-22-04-x64"
  name     = var.app_name
  region   = var.region
  size     = var.droplet_size
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  # Add cloud-init configuration to create user, set up SSH, and pass Spaces credentials to the droplet
  user_data = <<-EOF
    #cloud-config

    # Create the app user with sudo access
    users:
      - name: app
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys:
          - ${tls_private_key.ssh_key.public_key_openssh}

    write_files:
      # Create s3cmd config file with Spaces credentials
      - path: /root/.s3cfg
        content: |
          [default]
          access_key = ${digitalocean_spaces_key.backup_key.access_key}
          secret_key = ${digitalocean_spaces_key.backup_key.secret_key}
          host_base = ${var.spaces_region}.digitaloceanspaces.com
          host_bucket = %(bucket)s.${var.spaces_region}.digitaloceanspaces.com
        permissions: '0600'
      
      # Add environment variables for applications that need Spaces access
      - path: /etc/environment
        append: true
        content: |
          DO_SPACES_ACCESS_KEY=${digitalocean_spaces_key.backup_key.access_key}
          DO_SPACES_SECRET_KEY=${digitalocean_spaces_key.backup_key.secret_key}
          DO_SPACES_ENDPOINT=${var.spaces_region}.digitaloceanspaces.com
          DO_SPACES_BUCKET=${digitalocean_spaces_bucket.backup_bucket.name}

      # Configure SSH for secure access (only app user with public key)
      - path: /etc/ssh/sshd_config.d/99-secure-ssh.conf
        content: |
          # Disable root login
          PermitRootLogin no
          
          # Authentication settings
          PasswordAuthentication no
          ChallengeResponseAuthentication no
          UsePAM yes
          
          # Explicitly enable public key authentication
          PubkeyAuthentication yes
          
          # Allow only user 'app' to login
          AllowUsers app
          
          # Additional security settings
          X11Forwarding no
          PrintMotd no
          AcceptEnv LANG LC_*
          
          # Logging
          SyslogFacility AUTH
          LogLevel INFO
        permissions: '0644'
        
      # Configure Fail2Ban for SSH protection
      - path: /etc/fail2ban/jail.d/custom.conf
        content: |
          [sshd]
          enabled = true
          port = ssh
          filter = sshd
          logpath = /var/log/auth.log
          maxretry = 5
          bantime = 3600
          findtime = 600
        permissions: '0644'

      # Docker daemon secure configuration with improved log rotation
      - path: /etc/docker/daemon.json
        content: |
          {
            "log-driver": "json-file",
            "log-opts": {
              "max-size": "50m",
              "max-file": "5"
            },
            "live-restore": true,
            "userland-proxy": false,
            "no-new-privileges": true,
            "icc": false
          }
        permissions: '0644'

      # Basic logrotate configuration for system logs
      - path: /etc/logrotate.d/system-logs
        content: |
          # System logs rotation
          /var/log/syslog
          /var/log/auth.log
          /var/log/kern.log
          /var/log/messages {
            weekly
            rotate 4
            compress
            missingok
            notifempty
          }
        permissions: '0644'

    runcmd:
      # Update package lists and install required packages
      - apt-get update
      - apt-get install -y s3cmd ufw fail2ban unattended-upgrades apt-listchanges
      
      # Test the connection to Spaces
      - s3cmd ls s3://${digitalocean_spaces_bucket.backup_bucket.name}

      # Copy the s3cmd config to app's home directory
      - mkdir -p /home/app/.ssh
      - cp /root/.s3cfg /home/app/
      - chown app:app /home/app/.s3cfg
      - chmod 600 /home/app/.s3cfg

      # Restart SSH service to apply new configuration
      - systemctl restart sshd
      
      # Configure and enable UFW (Uncomplicated Firewall)
      - ufw default deny incoming
      - ufw default allow outgoing
      - ufw allow ssh
      - ufw allow 80/tcp
      - ufw allow 443/tcp
      - ufw --force enable
      
      # Configure and restart Fail2Ban
      - cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
      - systemctl enable fail2ban
      - systemctl restart fail2ban
      
      # Configure unattended-upgrades for automatic security updates
      - echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
      - echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
      - echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
      - echo 'APT::Periodic::AutocleanInterval "7";' >> /etc/apt/apt.conf.d/20auto-upgrades
      
      # Configure unattended-upgrades to only install security updates and reboot if necessary
      - echo 'Unattended-Upgrade::Allowed-Origins { "$${distro_id}:$${distro_codename}-security"; };' > /etc/apt/apt.conf.d/50unattended-upgrades
      - echo 'Unattended-Upgrade::Package-Blacklist { };' >> /etc/apt/apt.conf.d/50unattended-upgrades
      - echo 'Unattended-Upgrade::Automatic-Reboot "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
      - echo 'Unattended-Upgrade::Automatic-Reboot-Time "02:00";' >> /etc/apt/apt.conf.d/50unattended-upgrades
      - echo 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
      - echo 'Unattended-Upgrade::SyslogEnable "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades
      
      # Enable and start unattended-upgrades service
      - systemctl enable unattended-upgrades
      - systemctl start unattended-upgrades

      # Install Docker for Kamal v2
      - apt-get install -y apt-transport-https ca-certificates curl software-properties-common
      - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
      - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      - apt-get update
      - apt-get install -y docker-ce docker-ce-cli containerd.io
      - systemctl enable docker
      - systemctl start docker

      # Add app to docker group
      - usermod -aG docker app

      # Install btop (system resource monitor)
      - apt-get install -y btop

      # Install lazydocker (Docker management tool)
      - curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
      - mv /.local/bin/lazydocker /usr/local/bin/
      - chmod +x /usr/local/bin/lazydocker
      - rm -rf /.local

      # Create docker directory and restart Docker to apply secure configuration
      - mkdir -p /etc/docker
      - systemctl restart docker

      # Set up swap file
      - fallocate -l ${var.swap_size_mb}M /swapfile
      - chmod 600 /swapfile
      - mkswap /swapfile
      - swapon /swapfile
      - echo '/swapfile none swap sw 0 0' >> /etc/fstab

      # Configure swappiness and cache pressure
      - echo 'vm.swappiness=10' >> /etc/sysctl.conf
      - echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf

      # Enhance kernel security parameters
      - echo 'net.ipv4.tcp_syncookies=1' >> /etc/sysctl.conf
      - echo 'net.ipv4.conf.all.accept_redirects=0' >> /etc/sysctl.conf
      - echo 'net.ipv6.conf.all.accept_redirects=0' >> /etc/sysctl.conf
      - echo 'net.ipv4.conf.all.log_martians=1' >> /etc/sysctl.conf
      - sysctl -p

      # Set up a simple log cleanup script
      - |
        cat > /usr/local/bin/cleanup-old-logs.sh << 'EOFSCRIPT'
        #!/bin/bash
        # Find and remove log files older than 30 days
        find /var/log -type f -name "*.log.*" -o -name "*.gz" -mtime +30 -delete
        EOFSCRIPT
      - chmod +x /usr/local/bin/cleanup-old-logs.sh

      # Add weekly log cleanup cron job
      - echo "0 2 * * 0 root /usr/local/bin/cleanup-old-logs.sh > /dev/null 2>&1" > /etc/cron.d/cleanup-logs
      - chmod 644 /etc/cron.d/cleanup-logs
  EOF
}

# Create an SSH config entry
resource "local_file" "ssh_config" {
  content  = <<-EOT
# SSH Config
Host ${var.app_name}
  HostName ${digitalocean_droplet.droplet.ipv4_address}
  User app
  IdentityFile ~/.ssh/${var.app_name}_id_rsa
  EOT
  filename = pathexpand("~/.ssh/config.d/${var.app_name}")

  # This provisioner will provide instructions to add the entry to SSH config
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ~/.ssh/config.d
      echo 'To include this config in your SSH config, ensure you have the following in your ~/.ssh/config:'
      echo 'Include ~/.ssh/config.d/*'
    EOT
  }
}

# Create a DigitalOcean Spaces bucket for backups
resource "digitalocean_spaces_bucket" "backup_bucket" {
  name   = var.spaces_bucket_name != null ? var.spaces_bucket_name : "${var.app_name}-backups"
  region = var.spaces_region
  acl    = "private"
}

# Create a Spaces access key for programmatic access
resource "digitalocean_spaces_key" "backup_key" {
  name = "${var.app_name}-backup-key"
}

# Create a bucket policy to grant read/write access (excluding delete) to the backup bucket for the backup key
resource "digitalocean_spaces_bucket_policy" "backup_bucket_policy" {
  region = var.spaces_region
  bucket = digitalocean_spaces_bucket.backup_bucket.name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ReadWriteAccess",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${digitalocean_spaces_key.backup_key.access_key}:user/${var.app_name}-backup-key"
        },
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ],
        "Resource" : [
          "arn:aws:s3:::${digitalocean_spaces_bucket.backup_bucket.name}",
          "arn:aws:s3:::${digitalocean_spaces_bucket.backup_bucket.name}/*"
        ]
      }
    ]
  })
}
