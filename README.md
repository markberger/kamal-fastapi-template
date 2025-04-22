# kamal-fastapi-template

Quickly spin up a Digital Ocean droplet and deploy a
[FastAPI](https://fastapi.tiangolo.com/) "hello world" server with
[kamal](https://kamal-deploy.org/docs/installation/).

## Requirements

You will need a Digital Ocean account and a docker image registry (defaults to
Docker Hub).

```
# terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# kamal
gem install kamal

# dotenvx for secrets
brew install dotenvx/brew/dotenvx
```

## Deploy Droplet

For a detailed explanation of all actions, see
[terraform/README.md](terraform/README.md]).

```sh
cd terraform
terraform init

# Update app_name in terraform.tfvars. This will be used for
# ssh config, keys, and resource names
cp terraform.tfvars.example terraform.tfvars

# Examine what terraform will do. Notice that it creates:
# - ~/.ssh/${app_name}_id_rsa
# - ~/.ssh/${app_name}_id_rsa.pub
# - ~/.ssh/config.d/${app_name}
#
# You will need to add 'Include ~/.ssh/config.d/*'
# to your main SSH config
terraform plan

# Perform actions if everything looks good.
terraform apply

# You will be able to connect quickly, but cloud-init needs to finish.
# When you can run lazydocker with no issues, the server is ready.
# You may need to logout + login because adding the user to the docker
# group occurs late in the script
ssh app_name
```

## Deploy App

```sh
# Go back to top dir
cd ../

# Add registry password for docker hub here
cp .env.example .env

# Update config/deploy.yml with your docker hub username
# Deploy the fastapi project
kamal setup
```

Now navigate to the server's IP address in the browser. You should see:

```json
{ "message": "Hello World" }
```

When you're done, bring down the droplet (destructively!) with:

```sh
cd terraform && terraform destroy
```
