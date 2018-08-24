provider "aws" {
  region     = "$aws_region"
}

data "aws_vpc" "default" {
  default = "true"
}

module "channels" {
  source = "./modules/channels"

  bucket_name       = "$addons_bucket_name"
  bucket_key_prefix = "$cluster_name"       # no trailing slash
}

module "kops" {
  source = "./modules/kops"
}

resource "aws_security_group" "ingress" {
  name        = "ingress.$cluster_name"
  description = "ingress.$cluster_name"
  vpc_id      = "\${data.aws_vpc.default.id}"

  tags = "\${
    map(
      "kubernetes.io/cluster/$cluster_name", "owned",
      "kubernetes:application", "kube-ingress-aws-controller"
    )}"
}

resource "aws_security_group_rule" "allow_all_egress_on_ingress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "\${aws_security_group.ingress.id}"
}

resource "aws_security_group_rule" "allow_public_http_on_ingress" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "\${aws_security_group.ingress.id}"
}

resource "aws_security_group_rule" "allow_public_https_on_ingress" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "\${aws_security_group.ingress.id}"
}

resource "aws_security_group_rule" "allow_all_ingress_on_nodes" {
  count                    = "\${length(module.kops.node_security_group_ids)}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "\${aws_security_group.ingress.id}"

  security_group_id = "\${element(module.kops.node_security_group_ids,count.index)}"
  depends_on        = ["module.kops"]
}

## Certs for ALB

data "aws_route53_zone" "training" {
  name         = "$dns_zone."
  private_zone = false
}

resource "aws_acm_certificate" "training_wildcard" {
  domain_name       = "*.$dns_zone"
  validation_method = "DNS"
}

resource "aws_route53_record" "training_wildcard_cert_validation" {
  name    = "${lookup(aws_acm_certificate.training_wildcard.domain_validation_options[0],"resource_record_name")}"
  type    = "${lookup(aws_acm_certificate.training_wildcard.domain_validation_options[0],"resource_record_type")}"
  zone_id = "${data.aws_route53_zone.training.id}"
  records = ["${lookup(aws_acm_certificate.training_wildcard.domain_validation_options[0],"resource_record_value")}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "training_wildcard" {
  certificate_arn         = "${aws_acm_certificate.training_wildcard.arn}"
  validation_record_fqdns = ["${aws_route53_record.training_wildcard_cert_validation.fqdn}"]
}

