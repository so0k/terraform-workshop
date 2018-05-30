# Security Group Id: 
#   $sg_group
# Subnet Id:
#   $subnet_a
# AMI:
#   $ami

provider "aws" {
  access_key 	= "$aws_key" 
  secret_key 	= "$aws_secret"
  region      = "$aws_region"
}
