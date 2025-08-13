terraform {
  backend "s3" {
    bucket       = "terraform-593793056386-us-east-2"
    key          = "eks-istio-workshop/infra/main/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
