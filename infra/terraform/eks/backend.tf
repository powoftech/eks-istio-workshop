terraform {
  backend "s3" {
    bucket         = "terraform-state-593793056386"
    key            = "infra/eks/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-state-593793056386"

  }
}
