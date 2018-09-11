# 
# Generate an Azure PostgreSQL DB through terraform + terragrunt

# Using the tf.sh wrapper
## Requirements
* bash
* Azure CLI >= 2.0
* unzip
* curl
* terraform
* terragrunt
  
* environment variables as defined in [envrc-template](envrc_template). The tool [direnv](https://github.com/direnv/direnv) can help manage them.
* Or export to your current command env manually

## But why?
This repository includes a shell script that helps to automate a lot of common needs, such as:
* terraform/terragrunt version management and automatic download
* state management (in a remote backend)
* locking
* auto init
* multiple environments per stack


```bash
./tf.sh -a plan -s ../terraform-azurerm-db-postgresql/ -e dev -x -out=terraform.plan
```

```bash
./tf.sh -a apply -s ../terraform-azurerm-db-postgresql/ -e dev
```