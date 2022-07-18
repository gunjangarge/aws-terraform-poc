terraform {
  backend "s3" {
    bucket = "terraform-remote-dbsaas"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
