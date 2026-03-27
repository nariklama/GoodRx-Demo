provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "orders_analytics" {
  bucket = "orders-analytics-data"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "orders_analytics" {
  bucket = aws_s3_bucket.orders_analytics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "orders_analytics" {
  bucket = aws_s3_bucket.orders_analytics.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable SSE-S3 encryption (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "orders_analytics" {
  bucket = aws_s3_bucket.orders_analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle policy — transition to Intelligent-Tiering after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "orders_analytics" {
  bucket = aws_s3_bucket.orders_analytics.id

  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

# Bucket policy — restrict access to current AWS account only
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "orders_analytics" {
  statement {
    sid    = "DenyExternalAccess"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.orders_analytics.arn,
      "${aws_s3_bucket.orders_analytics.arn}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "orders_analytics" {
  bucket = aws_s3_bucket.orders_analytics.id
  policy = data.aws_iam_policy_document.orders_analytics.json

  depends_on = [aws_s3_bucket_public_access_block.orders_analytics]
}
