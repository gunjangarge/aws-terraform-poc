variable "aws_region" {
  default = "us-east-1"
}

variable "secret_key" {
  default = "<ACTUAL_SECRET_KEY>"
}

variable "access_key" {
  default = "<ACTUAL_ACCESS_KEY>"
}

variable "lambda_code_repo" {
  default = "https://github.com/gunjangarge/aws-lambda-poc.git"
}
