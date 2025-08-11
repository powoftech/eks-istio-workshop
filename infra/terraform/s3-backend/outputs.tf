output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.state_bucket.s3_bucket_name
}