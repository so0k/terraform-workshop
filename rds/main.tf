# Security Group Id: 
#   sg-6b1ea30d
# db subnets:
#   subnet-397baf5e
#   subnet-16ac565f
# ingress_source_cidrs:
#   172.31.0.0/16

variable aws_access_key {}
variable aws_secret_key {}

variable aws_region {
  default = "ap-southeast-1"
}

provider "aws" {
  version    = "~> 1.2"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}
