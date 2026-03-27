terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "aws-test21-admin"
}

data "aws_iam_policy_document" "orders_s3_write" {
  statement {
    sid    = "AllowOrdersAnalyticsWrite"
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::orders-analytics-logs-prod/events/*"
    ]
  }
}

resource "aws_iam_policy" "orders_analytics_write" {
  name        = "orders-analytics-s3-write"
  description = "Allows the Orders service to write event logs to the orders-analytics-logs-prod S3 bucket"
  policy      = data.aws_iam_policy_document.orders_s3_write.json
}

data "aws_iam_policy_document" "orders_service_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "orders_service" {
  name               = "orders-service-role"
  description        = "IAM role for the Orders service to write analytics events to S3"
  assume_role_policy = data.aws_iam_policy_document.orders_service_assume_role.json
}

resource "aws_iam_role_policy_attachment" "orders_service_s3_write" {
  role       = aws_iam_role.orders_service.name
  policy_arn = aws_iam_policy.orders_analytics_write.arn
}
