# following is for an automation user that can create
# ec2 instances and allows standard smg playbooks
# to operate on the account.
resource "aws_iam_access_key" "smgu" {
  user = aws_iam_user.smgu.name
}

resource "aws_iam_user" "smgu" {
  name = "${local.username}"
}

data "aws_iam_policy_document" "smgu_ro" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:CreateSecurityGroup",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:DescribeInstanceTypes",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeSubnets",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateKeyPair",
      "ec2:DeleteKeyPair",
      "ec2:ImportKeyPair",
      "ec2:DescribeDhcpOptions",
      "ec2:CreateDhcpOptions",
      "ec2:DeleteDhcpOptions",
      "ec2:AssociateDhcpOptions",
      "ec2:DescribeAddresses",
      "ec2:AllocateAddress",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:ReleaseAddress",
      "ec2:ModifyAddressAttribute",
      "ec2:ResetAddressAttribute"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "smgu_ro" {
  name   = "${local.iam_policyname}"
  user   = aws_iam_user.smgu.name
  policy = data.aws_iam_policy_document.smgu_ro.json
}


# following is for automated snaphots of instances on a 7 day cycle
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "${local.dlm_rolename}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "${local.iam_dlm_policyname}"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}

resource "aws_dlm_lifecycle_policy" "smg_dlm_policy" {
  description        = "${local.dlm_policydesc}"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  tags = {
    Name = "${local.dlm_policyname}"
  }

  policy_details {
    policy_type    = "EBS_SNAPSHOT_MANAGEMENT"
    resource_types = ["INSTANCE"]

    schedule {
      name = "1 week of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true

      variable_tags = {
        instance-id = "$(instance-id)"
        timestamp   = "$(timestamp)"
      }
    }

    target_tags = {
      Snapshot = "weekly"
    }

  }
}
