## Added for kops workshop

resource "aws_iam_user_policy_attachment" "aws_users_s3" {
  count      = "${length(var.users)}"
  user       = "${element(aws_iam_user.aws_users.*.name,count.index)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "aws_users_iam" {
  count      = "${length(var.users)}"
  user       = "${element(aws_iam_user.aws_users.*.name,count.index)}"
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_user_policy_attachment" "aws_users_vpc" {
  count      = "${length(var.users)}"
  user       = "${element(aws_iam_user.aws_users.*.name,count.index)}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state_store" {
  count  = "${length(var.users)}"
  bucket = "${data.aws_caller_identity.current.account_id}-${element(aws_iam_user.aws_users.*.name,count.index)}-kops-state-store"
  region = "${var.aws_region}"
  acl    = "private"

  tags {
    builtWith = "terraform"
    system    = "kops"
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
