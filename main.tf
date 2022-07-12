// Clone repository with lambda function code

resource "null_resource" "git_clone" {
  provisioner "local-exec" {
    command = "git clone ${var.lambda_code_repo}"
  }
}

// Create a ZIP of Python Application

data "archive_file" "zip_the_python_code" {
  depends_on  = [null_resource.git_clone]
  type        = "zip"
  source_dir  = "${path.module}/aws-lambda-poc/function"
  output_path = "${path.module}/aws-lambda-poc.zip"
}

resource "null_resource" "download_python_modules" {
  provisioner "local-exec" {
    command = "pip3 install --target ${path.module}/layer/python/lib/python3.8/site-packages/ -r ${path.module}/aws-lambda-poc/function/requirements.txt --upgrade"
  }
  depends_on = [null_resource.git_clone]
}

// pip3 install --target layer/python/lib/python3.8/site-packages/ -r requirements.txt --upgrade

// Create a ZIP of Python Modules

data "archive_file" "zip_the_python_modules" {
  depends_on  = [null_resource.download_python_modules]
  type        = "zip"
  source_dir  = "${path.module}/layer/"
  output_path = "${path.module}/aws-lambda-poc-modules.zip"
}

// AWS

// Add IAM Role
resource "aws_iam_role" "lambda_role" {
  name               = "DBasS_Test_Lambda_Function_Role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

// Add IAM Policy

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "DBasS_Test_Lambda_Function_Policy1"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

// Attach IAM Policy to IAM Role

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

// Add python modules as layer for lambda

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = "${path.module}/aws-lambda-poc-modules.zip"
  layer_name          = "aws_lambda_poc_lambda_layer"
  compatible_runtimes = ["python3.8"]
  // It will run after lambda layer zipfile build
  depends_on = [data.archive_file.zip_the_python_modules]

  lifecycle {
    create_before_destroy = true
  }
}

// Add aws_lambda_function Function

resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/aws-lambda-poc.zip"
  function_name = "aws_lambda_poc"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  layers        = [aws_lambda_layer_version.lambda_layer.arn]

  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}