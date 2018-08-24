resource "aws_iam_policy" "trainee_ec2" {
  count  = "${length(var.users)}"
  name   = "${var.users[count.index]}_ec2_policy"
  path   = "/"
  policy = "${element(data.aws_iam_policy_document.trainee_ec2.*.json,count.index)}"
}

resource "aws_iam_policy" "trainee_rds" {
  count  = "${length(var.users)}"
  name   = "${var.users[count.index]}_rds_policy"
  path   = "/"
  policy = "${element(data.aws_iam_policy_document.trainee_rds.*.json,count.index)}"
}

data "aws_iam_policy_document" "trainee_ec2" {
  # https://aws.amazon.com/blogs/security/demystifying-ec2-resource-level-permissions/
  count = "${length(var.users)}"

  statement {
    sid = "AllowDescribeForAllResources"

    actions = [
      "ec2:Describe*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "OnlyAllowCertainInstanceTypesToBeCreated"

    actions = [
      "ec2:RunInstances",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceType"

      values = [
        "t2.micro",
      ]
    }
  }

  statement {
    sid = "AllowUserToTagInstances"

    actions = [
      "ec2:CreateTags",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
    ]

    # allow any tag, but if tag is Owner, force it to username
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Owner"

      values = [
        "${var.users[count.index]}",
      ]
    }
  }

  statement {
    sid = "AllowAdditionalResourcesToSupportLaunchingEC2Instances"

    actions = [
      "ec2:RunInstances",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.aws_region}::image/ami-*",
    ]
  }

  statement {
    sid = "AllowUserToStopStartDeleteUntagHisInstances"

    actions = [
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:DeleteTags",
    ]

    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Owner"

      values = [
        "${var.users[count.index]}",
      ]
    }
  }
}

data "aws_iam_policy_document" "trainee_rds" {
  # INCOMPLETE - these IAM permissions for RDS are currently not finalised
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAM.AccessControl.IdentityBased.html
  count = "${length(var.users)}"

  statement {
    sid = "OnlyAllowCertainPostgressInstanceCreate"

    actions = [
      "rds:CreateDBInstance",
    ]

    resources = [
      "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:*",
    ]

    condition {
      test     = "StringEquals"
      variable = "rds:DatabaseEngine"

      values = [
        "postgres",
      ]
    }

    condition {
      test     = "Bool"
      variable = "rds:MultiAz"

      values = [
        false,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "rds:DatabaseClass"

      values = [
        "db.t2.micro",
        "db.t2.medium",
      ]
    }
  }

  # statement {
  #   sid = "AllowUserToCreateSG"


  #   actions = [
  #     "ec2:*SecurityGroup*",
  #   ]


  #   resources = [
  #     "*",
  #   ]
  # }

  statement {
    sid = "AllowMisc"

    actions = [
      "rds:CreateDBSecurityGroup",
      "rds:CreateDBSnapshot",
      "rds:CreateDBSubnetGroup",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:Delete*",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "DenyPIOPSCreate"
    effect = "Deny"

    actions = [
      "rds:CreateDBInstance",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "NumericNotEquals"
      variable = "rds:Piops"

      values = [
        "0",
      ]
    }
  }
}
