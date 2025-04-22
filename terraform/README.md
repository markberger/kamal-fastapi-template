# DigitalOcean Droplet Terraform Project for Kamal Deployment

This Terraform project provisions and configures a secure DigitalOcean Droplet
suitable for deploying applications with [Kamal](https://kamal-deploy.org/). It
performs the following actions:

1.  **Generates an SSH Key Pair:** Creates a new RSA SSH key pair and saves it
    locally to `~/.ssh/${var.app_name}_id_rsa` and
    `~/.ssh/${var.app_name}_id_rsa.pub`.
2.  **Adds SSH Key to DigitalOcean:** Uploads the public key to your
    DigitalOcean account.
3.  **Creates a Droplet:** Provisions a new Ubuntu 22.04 Droplet with specified
    size and region.
4.  **Configures the Droplet (via cloud-init):**
    - Creates a dedicated `app` user with `sudo` privileges and adds the
      generated SSH key for access.
    - Secures SSH access (disables root login, password authentication, allows
      only the `app` user).
    - Installs and configures UFW (Uncomplicated Firewall) to allow only SSH
      (22), HTTP (80), and HTTPS (443) traffic.
    - Installs and configures Fail2Ban to protect against brute-force SSH
      attacks.
    - Sets up `unattended-upgrades` for automatic security patching.
    - Installs Docker Engine, Docker CLI, and Containerd, configured securely
      for Kamal v2 compatibility.
    - Adds the `app` user to the `docker` group.
    - Installs useful utilities: `btop` (resource monitor) and `lazydocker`
      (Docker TUI).
    - Configures Docker daemon logging with rotation.
    - Sets up system log rotation (`logrotate`) and a cron job for periodic log
      cleanup.
    - Creates and configures a swap file for better memory management.
    - Applies kernel security parameter enhancements (`sysctl`).
5.  **Creates Local SSH Config:** Generates an SSH configuration file in
    `~/.ssh/config.d/${var.app_name}` for easy connection using
    `ssh ${var.app_name}`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.11.3
  installed.
- A [DigitalOcean](https://www.digitalocean.com/) account.
- A DigitalOcean API token with read/write access.

## Setup

1. Clone this repository

2. Set your DigitalOcean API token as an environment variable:

```bash
export DIGITALOCEAN_TOKEN=your_digitalocean_api_token_here
```

Alternatively, you can create a `terraform.tfvars` file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your desired values. You can uncomment and set
`do_token` here if you prefer not to use the environment variable. You might
also want to change `app_name`, `region`, `droplet_size`, or `swap_size_mb`.

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Preview the changes:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. When prompted, type `yes` to confirm.

5. After `terraform apply` completes successfully, it will output connection
   details and other information.

6. **Configure Local SSH:** Ensure your main SSH configuration file
   (`~/.ssh/config`) includes configurations from the `config.d` directory. If
   not, add the following line to `~/.ssh/config`:

   ```
   Include ~/.ssh/config.d/*
   ```

   _Note: The Terraform setup automatically creates the `~/.ssh/config.d`
   directory if it doesn't exist._

7. **Connect to Your Droplet:** Use the SSH alias created by Terraform (replace
   `myapp` with your `app_name` if you changed it):
   ```bash
   ssh myapp # Connects as the 'app' user
   ```
   Alternatively, use the command provided in the `ssh_connection_command`
   output.

## Cleanup

To destroy all resources created by this Terraform project:

```bash
terraform destroy
```

When prompted, type `yes` to confirm.

## Files

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `variables.tf` - Input variable definitions (e.g., `app_name`, `region`,
  `droplet_size`).
- `outputs.tf` - Output value definitions (e.g., `droplet_ip`,
  `ssh_connection_command`).
- `terraform.tfvars.example` - Example variables file.
- `terraform.tfvars` - Your specific variable values (create this from the
  example, ignored by git).
- `.gitignore` - Specifies intentionally untracked files that Git should ignore.
- `.terraform.lock.hcl` - Dependency lock file.

After running `terraform apply`, the following files will be created:

- `~/.ssh/${app_name}_id_rsa`: The private SSH key for accessing the droplet as
  the `app` user. **Keep this secure!**
- `~/.ssh/${app_name}_id_rsa.pub`: The corresponding public SSH key.
- `~/.ssh/config.d/${app_name}`: The SSH configuration snippet for easy
  connection.

## Outputs

After a successful `terraform apply`, the following outputs will be displayed:

- `droplet_ip`: The public IP address of the created Droplet.
- `ssh_private_key_path`: The local path to the generated private SSH key.
- `ssh_public_key_path`: The local path to the generated public SSH key.
- `ssh_config_path`: The local path to the generated SSH config entry file.
- `ssh_connection_command`: The command to connect to the droplet via SSH as the
  `app` user (e.g., `ssh myapp`).
- `ssh_config_instructions`: Reminder to include `~/.ssh/config.d/*` in your
  main SSH config.
- `security_updates_configured`: Confirmation that automatic security updates
  are enabled.
- `swap_configured`: Confirmation that swap space is configured.
- `log_rotation_configured`: Confirmation that log rotation is set up.
