#!/usr/bin/env bash
#(C)2019-2022 Pim Snel - https://github.com/mipmip/RUNME.sh
CMDS=();DESC=();NARGS=$#;ARG1=$1;make_command(){ CMDS+=($1);DESC+=("$2");};usage(){ printf "\nUsage: %s [command]\n\nCommands:\n" $0;line="              ";for((i=0;i<=$(( ${#CMDS[*]} -1));i++));do printf "  %s %s ${DESC[$i]}\n" ${CMDS[$i]} "${line:${#CMDS[$i]}}";done;echo;};runme(){ if test $NARGS -eq 1;then eval "$ARG1"||usage;else usage;fi;}
set -e

ROOTDIR=`pwd`

PROMPSTYLE='--prompt.foreground="213" --cursor.foreground="212" --width=0'

REGIONS=$(
cat <<'END_HEREDOC'
ap-south-1
eu-north-1
eu-west-3
eu-west-2
eu-west-1
ap-northeast-3
ap-northeast-2
ap-northeast-1
ca-central-1
sa-east-1
ap-southeast-1
ap-southeast-2
eu-central-1
us-east-1
us-east-2
us-west-1
us-west-2
END_HEREDOC
)

TFBACKENDTPL=$(
cat <<'END_HEREDOC'
# vim: set ft=hcl:
role_arn       = "ROLE_ARN"
bucket         = "STATE_BUCKET"
dynamodb_table = "terraform-state-lock"
END_HEREDOC
)


TFVARSTPL=$(
cat <<'END_HEREDOC2'
{
  "aws_account_id": "AWS_ACCOUNT_ID",
  "infra_environment": "ENVIRONMENT_NAME",
  "kms_arn" : "KMS_ARN"
}
END_HEREDOC2
)

DOMTFPROVIDERTPL=$(
cat <<'END_HEREDOC'
provider "aws" {
  region              = "DEF_REGION"
  allowed_account_ids = [ "${var.aws_account_id}" ]

  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/ROLE_NAME"
    session_name = "terraform_management_account"
  }

  default_tags {
    tags = {
      Project     = "PROJECT_NAME"
      Stack       = "shared"
    }
  }
}
END_HEREDOC
)

checkdeps(){
  if ! command -v $1 &> /dev/null
  then
    echo "<$1> could not be found"
    echo "  install this program first"
    exit 1
  fi
}

make_infra_environment(){

  if [ -d "./infra_environments/${ENVIRONMENT_NAME}" ]; then
    echo "ERROR: $ENVIRONMENT_NAME already exist."
    exit 1
  fi

  mkdir -p ./infra_environments/$ENVIRONMENT_NAME

  STATE_BUCKET="terraform-state-${AWS_ACCOUNT_ID}-${ENVIRONMENT_NAME}"

  TFBACKENDTPL="${TFBACKENDTPL/STATE_BUCKET/"$STATE_BUCKET"}"
  echo "${TFBACKENDTPL/ROLE_ARN/"$ROLE_ARN"}" > ./infra_environments/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.tfbackend

  TFVARSTPL="${TFVARSTPL/AWS_ACCOUNT_ID/"$AWS_ACCOUNT_ID"}"
  TFVARSTPL="${TFVARSTPL/ENVIRONMENT_NAME/"$ENVIRONMENT_NAME"}"
  echo "$TFVARSTPL" > ./infra_environments/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.tfvars.json
}

##### PLACE YOUR COMMANDS BELOW #####

get_project_vals(){
  DEF_REGION=`cat stack/01_shared_kms/tf_backend.tf | yj -cj | jq -r ".terraform[0].backend[0].s3[0].region"`
  PROJECT_NAME=`cat stack/01_shared_kms/providers.tf | yj -cj | jq -r ".provider[0].aws[0].default_tags[0].tags[0].Project"`
  ROLE_NAME=`cat stack/01_shared_kms/providers.tf | yj -cj | jq -r ".provider[0].aws[0].assume_role[0].role_arn" | cut -d "/" -f 2`

  if [ -z "$PROJECT_NAME" ]
  then
    echo "ERROR project name is missing. Is the project initialized?"
  fi
  if [ -z "$DEF_REGION" ]
  then
    echo "ERROR default region is missing. Is the project initialized?"
  fi
  if [ -z "$ROLE_NAME" ]
  then
    echo "ERROR role name is missing. Is the project initialized?"
  fi
}

init_env(){

  get_project_vals

  ENVIRONMENT_NAME=`gum input ${PROMPSTYLE} --prompt "Enter environment name: " `
  AWS_ACCOUNT_ID=`gum input ${PROMPSTYLE} --prompt "Enter destination AWS Account Id: " --placeholder="000000000000" --char-limit=12`
  ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align left --width 100 --margin "1 2" --padding "2 4" \
    "Project name:       ${PROJECT_NAME}" \
    "Default Region:     ${DEF_REGION}" \
    "Environment name:   ${ENVIRONMENT_NAME}" \
    "AWS account ID:     ${AWS_ACCOUNT_ID}" \
    "Role ARN:           ${ROLE_ARN}" \

  gum confirm "Check if above information is correct? Continue?" && continue=1 || exit 1

  echo "continue"

  make_infra_environment
}

init_domain(){
  cd $ROOTDIR
  DOMAIN_KEY="$1"
  DOMAIN_PATH="stack/$1"
  cd $DOMAIN_PATH

  if [ -f providers.tf ]; then
    echo "ERROR: providers.tf exist in ${DOMAIN_PATH}. project has already been setup"
    exit 1
  fi
  if [ -f tf_backend.tf ]; then
    echo "ERROR: tf_backend.tf exist in ${DOMAIN_PATH}. project has already been setup"
    exit 1
  fi


  DOMTFBACKENDTPL=$(
  cat <<'END_HEREDOC'
terraform {
  backend "s3" {
    session_name = "TerraformStateUpdate"
    region       = "DEF_REGION"
    key          = "DOMAIN_KEY/terraform.tf"
  }
}
END_HEREDOC
  )

  DOMTFPROVIDERTPL="${DOMTFPROVIDERTPL/DEF_REGION/"$DEF_REGION"}"
  DOMTFPROVIDERTPL="${DOMTFPROVIDERTPL/ROLE_NAME/"$ROLE_NAME"}"
  DOMTFPROVIDERTPL="${DOMTFPROVIDERTPL/PROJECT_NAME/"$PROJECT_NAME"}"
  echo "$DOMTFPROVIDERTPL" > providers.tf

  DOMTFBACKENDTPL="${DOMTFBACKENDTPL/DEF_REGION/"$DEF_REGION"}"
  DOMTFBACKENDTPL="${DOMTFBACKENDTPL/DOMAIN_KEY/"$DOMAIN_KEY"}"
  echo "$DOMTFBACKENDTPL" > tf_backend.tf

}

setup_domain_with_local_state(){
  cd $ROOTDIR
  DOMAIN_PATH="stack/$1"
  cd $DOMAIN_PATH

  rm -Rf ./.terraform
  rm -Rf ./.terraform.lock.hcl

  mv tf_backend.tf tf_backend.disable

  terraform init
  terraform apply -auto-approve -compact-warnings -var-file=../../infra_environments/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.tfvars.json
}

update_kms_arn_in_tfvars(){
  cd $ROOTDIR
  cd stack/01_shared_kms
  KMS_ARN=`terraform output -raw default_kms_key_arn`
  cd $ROOTDIR
  envfile="infra_environments/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.tfvars.json"
  cat $envfile | jq --arg KMS_ARN "$KMS_ARN" '.kms_arn=$KMS_ARN' > /tmp/NEWENVFILE
  rm $envfile
  mv /tmp/NEWENVFILE $envfile
}

migrate_domain(){
  cd $ROOTDIR
  DOMAIN_KEY="$1"
  DOMAIN_PATH="stack/$1"
  cd $DOMAIN_PATH
  backend_file="../../infra_environments/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.tfbackend"

  mv tf_backend.disable tf_backend.tf

  terraform init -backend-config="${backend_file}" -migrate-state -force-copy
  rm terraform.tfstate
  rm terraform.tfstate.backup
}


make_command "requirements" "Show requirements"
requirements(){
  echo "- Project wide admin_role. All accounts should have this role with proper permissions"
  echo "- Project wide default region. The Terraform States are stored in this region per account"
}

##1
make_command "init_project" "Create infra conf files"
init_project(){

  PROJECT_NAME=`gum input ${PROMPSTYLE} --prompt "Enter Project name: "`
  ROLE_NAME=`gum input ${PROMPSTYLE} --prompt "Enter Admin Role name: " --value='landing_zone_devops_administrator'`
  DEF_REGION=`echo "${REGIONS}" | gum filter --prompt "Enter default region: "`

  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align left --width 80 --margin "1 2" --padding "2 4" \
    "Project name:        ${PROJECT_NAME}" \
    "Admin Role Name:     ${ROLE_NAME}" \
    "Default region:      ${DEF_REGION}" \

  gum confirm "Check if above information is correct? Continue?" && continue=1 || exit 1

  init_domain "01_shared_kms"
  init_domain "02_backend_config"
  init_domain "03_sqs_dlq"
}

clean_domain(){
  cd $ROOTDIR
  DOMAIN_KEY="$1"
  DOMAIN_PATH="stack/$1"
  cd $DOMAIN_PATH

  rm -Rf ./.terraform
  rm -Rf ./.terraform.lock.hcl
  rm -Rf ./providers.tf
  rm -Rf ./tf_backend.tf
  rm -Rf terraform.tfstate
  rm -Rf terraform.tfstate.backup
}

clean_project(){
  rm -Rf infra_environment
  clean_domain "01_shared_kms"
  clean_domain "02_backend_config"
  clean_domain "03_sqs_dlq"
}

##2
make_command "bootstrap_infra_env" "Create infra conf files"
bootstrap_infra_env(){

  init_env
  #ENVIRONMENT_NAME=`ls ./infra_environments/| gum choose`

  setup_domain_with_local_state "01_shared_kms"
  update_kms_arn_in_tfvars
  setup_domain_with_local_state "02_backend_config"
  setup_domain_with_local_state "03_sqs_dlq"

  migrate_domain "01_shared_kms"
  migrate_domain "02_backend_config"
  migrate_domain "03_sqs_dlq"
}

make_command "awsnuke" "nuke this account"
awsnuke(){
  nix run nixpkgs#aws-nuke -- --profile technative_pg-playground_pim -c confignuke --no-dry-run
}

##### PLACE YOUR COMMANDS ABOVE #####
checkdeps "jq"
checkdeps "yj"
checkdeps "gum"
runme
