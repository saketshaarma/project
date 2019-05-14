pipeline {
    agent any
    stages {
        stage('---Terraform Plan---'){
            steps {
                terraform plan -var-file="input.tfvars"
            }
        }
        stage('---Deploy---'){
          steps {
              terraform apply -var-file="input.tfvars" -auto-approve
          }
        }
    }
}
