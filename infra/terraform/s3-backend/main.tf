provider "aws" {
  region = "us-east-2"
}

locals {
  tags = {
    ManagedBy = "Terraform"
  }
}

# S3 Backend Configuration
# 
# This module creates an S3 bucket for storing Terraform state files with the following features:
# - Bucket name format: terraform-{account-id}-{region}
# - Versioning enabled for state file history and recovery
# - Server-side encryption using AES256 algorithm
# - Public access blocked for security (all public access settings disabled)
# - Force destroy enabled to allow bucket deletion even with objects
# - Tagged with local tags for resource management
#
# The bucket serves as a remote backend for Terraform state management, providing:
# - State locking capabilities when combined with DynamoDB
# - Centralized state storage for team collaboration
# - State file versioning for rollback scenarios
# - Encryption at rest for sensitive infrastructure data
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "terraform-${data.aws_caller_identity.current.account_id}-${data.aws_region.selected.region}"
  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags
}
