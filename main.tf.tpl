# Security Group Id: 
#   sg-9d308dfb
# Subnet Id:
#   subnet-397baf5e

provider "aws" {
    access_key 	= "$aws_key" 
    secret_key 	= "$aws_secret"
    region 		= "$aws_region"
}
