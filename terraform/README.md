# DigitalOcean Infrastructure Terraform Project

This Terraform project creates a DigitalOcean infrastructure with a droplet and
Spaces bucket. It:

1. Generates an SSH key pair and stores it in your ~/.ssh directory
2. Adds the SSH key to your DigitalOcean account
3. Creates a droplet with the SSH key attached
4. Creates an SSH config entry in ~/.ssh/config.d/ for easy access
5. Creates a Spaces bucket for database backups
6. Generates access keys for the Spaces bucket

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

3. Set your Spaces API credentials as environment variables:

```bash
export SPACES_ACCESS_KEY_ID=your_spaces_access_key_here
export SPACES_SECRET_ACCESS_KEY=your_spaces_secret_key_here
```

These environment variables are required for Terraform to create and configure
the Spaces bucket and access keys. If you don't have existing Spaces
credentials, you can create them in the DigitalOcean control panel under API >
Spaces keys.

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
ssh ${app_name}-server
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

## Generated Files

After running `terraform apply`, the following files will be created:

- `~/.ssh/${app_name}_id_rsa` - Private SSH key
- `~/.ssh/${app_name}_id_rsa.pub` - Public SSH key
- `~/.ssh/config.d/${app_name}` - SSH config entry

## Using the Spaces Bucket

The Terraform configuration creates a DigitalOcean Spaces bucket for storage.
After applying the Terraform configuration, you'll receive the following outputs
related to the Spaces bucket:

- `spaces_bucket_name` - The name of your Spaces bucket
- `spaces_bucket_endpoint` - The endpoint URL for your Spaces bucket
- `spaces_access_key` - The access key for your Spaces bucket (sensitive)
- `spaces_secret_key` - The secret key for your Spaces bucket (sensitive)

You can view these outputs with:

```bash
terraform output
```

For sensitive values:

```bash
terraform output -raw spaces_access_key
terraform output -raw spaces_secret_key
```

The Spaces bucket can be accessed using S3-compatible tools and libraries, as
DigitalOcean Spaces is compatible with the S3 API.

## Automatic Spaces Credentials Configuration

This Terraform configuration automatically passes the Spaces access key and
secret key to the droplet using cloud-init. When the droplet is created, the
following is set up:

1. An `.s3cfg` configuration file is created in the root user's home directory
   with the Spaces credentials, allowing immediate use of the `s3cmd` tool.

2. Environment variables are added to `/etc/environment` with the Spaces
   credentials:

   - `DO_SPACES_ACCESS_KEY`
   - `DO_SPACES_SECRET_KEY`
   - `DO_SPACES_ENDPOINT`
   - `DO_SPACES_BUCKET`

3. The `s3cmd` tool is automatically installed for interacting with the Spaces
   bucket.

4. A test connection to the Spaces bucket is made during the initial setup.

This means that applications running on the droplet can immediately access the
Spaces bucket without additional configuration. You can use the environment
variables in your applications or scripts to access the Spaces bucket.

Example of using the environment variables in a bash script:

```bash
#!/bin/bash
# Example script to upload a file to Spaces
FILE_TO_UPLOAD="example.txt"
REMOTE_PATH="backups/example.txt"

s3cmd put $FILE_TO_UPLOAD s3://$DO_SPACES_BUCKET/$REMOTE_PATH
```

Or in a Python script using boto3:

```python
import os
import boto3

# Get credentials from environment variables
access_key = os.environ.get('DO_SPACES_ACCESS_KEY')
secret_key = os.environ.get('DO_SPACES_SECRET_KEY')
endpoint = os.environ.get('DO_SPACES_ENDPOINT')
bucket_name = os.environ.get('DO_SPACES_BUCKET')

# Create a session with the Spaces credentials
session = boto3.session.Session()
client = session.client('s3',
                        region_name='nyc3',
                        endpoint_url=f'https://{endpoint}',
                        aws_access_key_id=access_key,
                        aws_secret_access_key=secret_key)

# Upload a file
client.upload_file('example.txt', bucket_name, 'backups/example.txt')
```
