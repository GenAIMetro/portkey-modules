locals {
  dynamic_tags = {
    ProjectName = var.name
    Environment = var.environment
    Terraform   = "true"
  }
  default_tags = merge(local.dynamic_tags, var.addon_tags)
}

module "s3_bucket_for_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.name}-${var.environment}-log"
  acl    = "log-delivery-write"

  # Allow deletion of non-empty bucket
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = false
}

resource "aws_iam_user" "s3_logs" {
  name = "${var.name}-${var.environment}-s3-user"
  tags = merge({ Name = "${var.name}-${var.environment}-s3-user" }, local.default_tags)
}

resource "aws_iam_access_key" "s3_logs" {
  user = aws_iam_user.s3_logs.name
}

resource "aws_iam_policy" "s3_logs" {
  name        = "${var.name}${var.environment}-s3-logs-policy"
  description = "Policy for Terraform to manage S3 bucket and objects for s3 logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:PutBucketPolicy",
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.name}-${var.environment}-log",
          "arn:aws:s3:::${var.name}-${var.environment}-log/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "logs_attach_policy" {
  user       = aws_iam_user.s3_logs.name
  policy_arn = aws_iam_policy.s3_logs.arn
}