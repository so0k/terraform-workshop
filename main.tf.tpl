# Security Group Id: 
#   sg-6b1ea30d
# Subnet Id:
#   subnet-397baf5e
# AMI:
#   ami-032fb460

provider "aws" {
  access_key 	= "$aws_key" 
  secret_key 	= "$aws_secret"
  region        = "$aws_region"
}
