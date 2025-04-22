# DigitalOcean Infrastructure Terraform Project

This Terraform project creates a DigitalOcean infrastructure with a droplet. It:

1. Generates an SSH key pair and stores it in your ~/.ssh directory
2. Adds the SSH key to your DigitalOcean account
3. Creates a droplet with the SSH key attached
4. Creates an SSH config entry in ~/.ssh/config.d/ for easy access

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (v1.0.0+)
- A [DigitalOcean](https://www.digitalocean.com/) account
- A DigitalOcean API token with write access

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

And uncomment and edit the `do_token` line:

```
do_token = "your_digitalocean_api_token_here"
```

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

5. After the apply completes, ensure your SSH config includes the config.d
   directory:

```bash
# Add this line to your ~/.ssh/config if it's not already there
Include ~/.ssh/config.d/*
```

6. Connect to your droplet:

```bash
ssh ${var.app_name} # Connects as user 'app'
```

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
- `terraform.tfvars` - Variable values (you create this)
- `.gitignore` - Git ignore file for sensitive data

After running `terraform apply`, the following files will be created:

- `~/.ssh/${app_name}_id_rsa` - Private SSH key
- `~/.ssh/${app_name}_id_rsa.pub` - Public SSH key
- `~/.ssh/config.d/${var.app_name}` - SSH config entry
