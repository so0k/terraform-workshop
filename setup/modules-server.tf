resource "aws_instance" "tf_modules" {
  vpc_security_group_ids = ["${aws_security_group.workshop.id}"]
  user_data              = "${data.template_cloudinit_config.tf_modules.rendered}"
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.medium"

  key_name = "${var.users[0]}" # rider01 has full access to modules instance

  # ssh -i generated/rider01 ubuntu@modules.training.swatrider.com

  tags {
    Name = "tf-modules-server"
  }
  lifecycle {
    ignore_changes = ["user_data", "ami"]
  }
}

data "template_cloudinit_config" "tf_modules" {
  gzip          = false
  base64_encode = false

  # human readable cloud-config
  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.tf_modules_cloudconfig.rendered}"
  }
}

data "template_file" "tf_modules_cloudconfig" {
  template = "${file("./templates/tf-modules-cloud-config.tpl")}"

  vars {
    sigil_version  = "0.4.0"
    docker_version = "18.06.0~ce~3-0~ubuntu"
    aws_key        = "${aws_iam_access_key.tf_modules.id}"
    aws_secret     = "${aws_iam_access_key.tf_modules.secret}"
    aws_region     = "${var.aws_region}"
    modules_bucket = "${aws_s3_bucket.tf_modules.id}"
  }
}

resource "aws_s3_bucket" "tf_modules" {
  bucket = "${data.aws_caller_identity.current.account_id}-tf-modules"
  region = "${var.aws_region}"
  acl    = "private"

  force_destroy = "true"

  tags {
    builtWith = "terraform"
    system    = "modules"
  }

  versioning {
    enabled = false
  }

  lifecycle {
    # prevent_destroy = true
  }
}

# Defines a user that should be able to write to tf modules bucket
resource "aws_iam_user" "tf_modules" {
  name          = "tf_modules_user"
  path          = "/"
  force_destroy = "true"
}

resource "aws_iam_access_key" "tf_modules" {
  user = "${aws_iam_user.tf_modules.name}"
}

resource "aws_iam_user_policy" "tf_modules" {
  name   = "tf_modules"
  user   = "${aws_iam_user.tf_modules.name}"
  policy = "${data.aws_iam_policy_document.tf_modules.json}"
}

data "aws_iam_policy_document" "tf_modules" {
  # allow listing of all buckets
  statement {
    sid = "1"

    actions = [
      "s3:ListAllMyBuckets",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }

  # bucket level actions
  statement {
    sid = "2"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListObjects",
    ]

    resources = [
      "${aws_s3_bucket.tf_modules.arn}",
      "${aws_s3_bucket.tf_modules.arn}/*",
    ]
  }
}

resource "aws_route53_record" "tf_modules" {
  zone_id = "${aws_route53_zone.training.zone_id}"
  name    = "modules.${var.subdomain}.${var.domain}.${var.tld}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.tf_modules.public_ip}"]
}

resource "aws_route53_record" "tf_modules_internal" {
  zone_id = "${aws_route53_zone.training_internal.zone_id}"
  name    = "modules.internal.${var.subdomain}.${var.domain}.${var.tld}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.tf_modules.private_ip}"]
}
