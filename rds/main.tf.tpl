# Security Group Id: 
#   $sg_group
# db subnets:
#   $subnet_a
#   $subnet_b
# ingress_source_cidrs:
#   172.31.0.0/16

variable aws_access_key {}
variable aws_secret_key {}

variable aws_region {
  default = "$aws_region"
}

provider "aws" {
  version    = "~> 1.2"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}
