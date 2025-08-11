provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}

module "state_bucket" {
  source = "./modules/state-bucket"

  name = "terraform-state-${data.aws_caller_identity.current.account_id}"
}
