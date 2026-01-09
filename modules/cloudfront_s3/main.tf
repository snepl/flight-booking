locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)

  use_custom_domain = length(var.domain_names) > 0 && var.acm_cert_arn_us_east_1 != ""
}

data "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.name}-oac"
  description                       = "OAC for S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "${local.name} frontend"
  default_root_object = "index.html"

  origin {
    domain_name              = data.aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = "s3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "s3-${var.bucket_name}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.use_custom_domain ? false : true
    acm_certificate_arn            = local.use_custom_domain ? var.acm_cert_arn_us_east_1 : null
    ssl_support_method             = local.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.use_custom_domain ? "TLSv1.2_2021" : "TLSv1.2_2021"
  }

  aliases = local.use_custom_domain ? var.domain_names : null

  tags = merge(local.common_tags, { Name = "${local.name}-cloudfront" })
}

# Allow CloudFront to read S3
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "AllowCloudFrontRead"
    actions = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = data.aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}
