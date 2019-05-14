pipeline {
    agent any
    stages {
        stage('---Terraform Init---'){
            steps {
                terraform init
            }
        }
        stage('---Terraform Plan---'){
            steps {
                terraform plan "--var-file=input.tfvars" -var "aws_access_key=$TF_VAR_access_key" -var "aws_secret_key=$TF_VAR_secret_key" -var "aws_region=$TF_VAR_region"
            }
        }
        stage('---Deploy---'){
          steps {
              terraform apply "--var-file=input.tfvars" -var "aws_access_key=$TF_VAR_access_key" -var "aws_secret_key=$TF_VAR_secret_key" -var "aws_region=$TF_VAR_region" -auto-approve
          }
        }
    }
}
