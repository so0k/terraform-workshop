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
