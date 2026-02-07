# S3 Module - Creates independent S3 bucket

resource "aws_s3_bucket" "independent" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Purpose     = "independent-storage"
  }
}

resource "aws_s3_bucket_versioning" "independent" {
  bucket = aws_s3_bucket.independent.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "independent" {
  bucket = aws_s3_bucket.independent.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "independent" {
  bucket = aws_s3_bucket.independent.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
