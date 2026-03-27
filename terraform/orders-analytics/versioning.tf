# Enable versioning on the orders-analytics-data S3 bucket
resource "aws_s3_bucket_versioning" "orders_analytics" {
  bucket = "orders-analytics-data"

  versioning_configuration {
    status = "Enabled"
  }
}
