output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.state_bucket.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for state locking"
  value       = module.state_bucket.dynamodb_table_name
}