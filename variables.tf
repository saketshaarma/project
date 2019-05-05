variable "aws_secret_key" {
  description = "AWS IAM secret key for accessing AWS API"
}

variable "aws_access_key" {
  description = "AWS access key for accessing AWS API"
}

variable "aws_region" {
  description = "aws region in which deployment needs to be done"

}
variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR which you want to create"
}

variable "public_cidr" {
  description = "PUBLIC CIDR for complete whitelisting"
}

variable "aws_instance_iamge" {
  description = "AWS AMI name"
}

variable "aws_instance_type" {
  description = "Instance Type"
}

variable "aws_key_name" {
  description = "AWS key pair name"
}
variable "aws_key_pair_public" {
  description = "Public key of aws key pair"
}
