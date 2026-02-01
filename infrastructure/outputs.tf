output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.portfolio.id
}

output "website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.portfolio.website_endpoint
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.portfolio.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.portfolio.id
}

output "website_url" {
  description = "Website URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.portfolio.domain_name}"
}

output "nameservers" {
  description = "Route 53 nameservers (if custom domain is used)"
  value       = var.domain_name != "" ? aws_route53_zone.portfolio[0].name_servers : null
}