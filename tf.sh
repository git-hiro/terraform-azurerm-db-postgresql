#!/usr/bin/env bash
#
# vim: ft=sh

### Wrapper for Terraform ###

set -e
[[ $TRACE ]] && set -x

# Functions
log() {
  echo "* [${2:-INFO}] $1"
}

die() {
  >&2 log "$1" "ERROR"
  exit 1
}

# Get arguments
while getopts ':a:e:s:nx:' OPT; do
  case $OPT in
    a)  action=$OPTARG;;
    e)  env=$OPTARG;;
    s)  stack=$OPTARG;;
    n)  nocolour='-no-color';;
    x)  xtraopts=$OPTARG;;
  esac
done

# Vars
repo_root=$(git rev-parse --show-toplevel)
arch=$(uname | tr '[:upper:]' '[:lower:]')
tf_url='https://releases.hashicorp.com/terraform'
tf_version="${TERRAFORM_VERSION:-0.11.8}"
tg_url='https://github.com/gruntwork-io/terragrunt/releases/download'
tg_version="${TERRAGRUNT_VERSION:-0.16.8}"

# Usage
help="
  usage: $0 [ -a value -e value -s value -x 'value(s)' ]

     -a --> action: plan, push, apply, destroy
     -e --> environment name
     -s --> stack name (relative path to stack directory)
     -n --> disable colour output
     -x --> extra options: terraform args (optional)
"

# Test input vars
if [[ -z "$action" ]] || [[ -z "$env" ]] || [[ -z "$stack" ]]; then
  echo "$help"
  die "Required args not entered!"
fi

# Test TG version
tg_current=$(terragrunt -version | awk 'NR==1' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
while [ "$tg_current" != "$tg_version" ]; do
  log "Wrong Terragrunt version (current: ${tg_current:-none}, required: ${tg_version}), downloading..."
  curl -# -L -o $repo_root/bin/terragrunt \
    ${tg_url}/v${tg_version}/terragrunt_${arch}_amd64; \
    chmod +x $repo_root/bin/terragrunt; \
    tg_current=$tg_version; \
    log "Terragrunt version $tg_current download complete"
done

# Test TF version
tf_current=$(terraform version | awk 'NR==1' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
while [ "$tf_current" != "$tf_version" ]; do
  log "Wrong Terraform version (current: ${tf_current:-none}, required: ${tf_version}), downloading..."
  curl -# -L -o $repo_root/bin/terraform.zip \
    ${tf_url}/${tf_version}/terraform_${tf_version}_${arch}_amd64.zip; \
    unzip -q -o $repo_root/bin/terraform.zip -d $repo_root/bin && \
    rm $repo_root/bin/terraform.zip; \
    chmod +x $repo_root/bin/terraform; \
    tf_current=$tf_version; \
    log "Terraform version $tf_current download complete"
done

# Move in to stack directory
cd ${repo_root}/$stack \
  || die "Failed to change directory to ${repo_root}/$stack"

# State
short_alphanum_stack_name=$(basename $(pwd) | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-24 )
storage_account_name="${short_alphanum_stack_name}"
state_container_name="${short_alphanum_stack_name}-${env}-tfstate"

#create resource group
resource_group_name="terraform-backend"
resource_group_location=${TF_VAR_location}

az login --service-principal -u "${ARM_CLIENT_ID}" --password "${ARM_CLIENT_SECRET}" --tenant "${ARM_TENANT_ID}" > /dev/null
az account set -s "${ARM_SUBSCRIPTION_ID}" > /dev/null

resource_group_id=$(az group show --name "${resource_group_name}" -o tsv --query id)
if [ -z "${resource_group_id}" ]; then
  echo "resource group ${resource_group_name} doesn't exist, creating it..."
  az group create --name "${resource_group_name}" --location "${resource_group_location}"
else
  echo "resource group ${resource_group_name} already exists, continuing..."
fi

#create storage account
storage_account_id=$(az storage account show --resource-group ${resource_group_name} --name "${storage_account_name}" -o tsv --query id) || true
if [ -z "${storage_account_id}" ]; then
  echo "storage account ${storage_account_name} doesn't exist, creating it..."
  az storage account create --name "${storage_account_name}" --resource-group "${resource_group_name}" --access-tier Hot --kind BlobStorage --https-only true --encryption-services blob --sku 'Standard_RAGRS'
else
  echo "storage account ${storage_account_name} already exists, continuing..."
fi

#create storage container
echo "creating storage container ${state_container_name} if it doesn't exist..."
az storage container create -n "${state_container_name}" --account-name "${storage_account_name}"

log "Running 'terraform $action' for $stack stack in environment $env"
TF_VAR_state_resource_group_name=$resource_group_name \
TF_VAR_state_storage_account_name=$storage_account_name \
TF_VAR_state_container=$state_container_name \
TF_VAR_stack=$stack \
TF_VAR_environment=$env \
TF_VAR_terraform_version=tf_version \
terragrunt $action \
  --terragrunt-non-interactive \
  $nocolour \
  $xtraopts
