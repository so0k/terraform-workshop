## Added for kops workshop

resource "aws_s3_bucket" "state_store" {
  count  = "${length(var.users)}"
  bucket = "${data.aws_caller_identity.current.account_id}-${element(aws_iam_user.aws_users.*.name,count.index)}-kops-state-store"
  region = "${var.aws_region}"
  acl    = "private"

  force_destroy = "true"

  tags {
    builtWith = "terraform"
    system    = "kops"
  }

  versioning {
    enabled = true
  }

  lifecycle {
    # prevent_destroy = true
  }
}

resource "aws_s3_bucket" "addons_store" {
  count  = "${length(var.users)}"
  bucket = "${data.aws_caller_identity.current.account_id}-${element(aws_iam_user.aws_users.*.name,count.index)}-kops-addons"
  region = "${var.aws_region}"
  acl    = "private"

  force_destroy = "true"

  tags {
    builtWith = "terraform"
    system    = "kops"
  }

  versioning {
    enabled = true
  }

  lifecycle {
    # prevent_destroy = true
  }
}

## Certs for ALBs
data "aws_route53_zone" "training" {
  name         = "${var.subdomain}.${var.domain}.${var.tld}."
  private_zone = false
}

resource "aws_acm_certificate" "training_wildcard" {
  domain_name       = "*.${var.subdomain}.${var.domain}.${var.tld}"
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
