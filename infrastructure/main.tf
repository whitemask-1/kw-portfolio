provider "aws" {
  region = var.aws_region
}

# S3 bucket for website hosting
resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name

  tags = {
    Name        = "Portfolio Website"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# Enable S3 versioning for backup and recovery
resource "aws_s3_bucket_versioning" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access - CloudFront OAI will handle access
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "portfolio" {
  comment = "OAI for portfolio website"
}

# S3 bucket policy allowing only CloudFront OAI
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.portfolio.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.portfolio]
}

# S3 bucket for CloudFront access logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"

  tags = {
    Name        = "Portfolio CloudFront Logs"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront distribution for CDN + HTTPS
resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = var.domain_name != "" ? [var.domain_name] : []
  price_class         = "PriceClass_100" # Use only North America and Europe edge locations

  # Enable logging
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  origin {
    domain_name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.portfolio.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portfolio.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-${aws_s3_bucket.portfolio.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # Security headers
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" ? true : false
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate.portfolio[0].arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021" # Strong TLS only
  }

  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/index.html"
  }

  tags = {
    Name        = "Portfolio CDN"
    Environment = "Production"
  }
}

# CloudFront Response Headers Policy for Security
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "portfolio-security-headers"
  comment = "Security headers for portfolio website"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:;"
      override                = true
    }
  }
}

# SSL Certificate (only if custom domain is provided)
resource "aws_acm_certificate" "portfolio" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Portfolio SSL Certificate"
  }
}

# Route 53 hosted zone (only if custom domain is provided)
resource "aws_route53_zone" "portfolio" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "Portfolio DNS Zone"
  }
}

# DNS records for ACM certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.portfolio[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = aws_route53_zone.portfolio[0].zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "portfolio" {
  count                   = var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.portfolio[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# A record pointing to CloudFront
resource "aws_route53_record" "portfolio" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.portfolio[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.portfolio.domain_name
    zone_id                = aws_cloudfront_distribution.portfolio.hosted_zone_id
    evaluate_target_health = false
  }
}