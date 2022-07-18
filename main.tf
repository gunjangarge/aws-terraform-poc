resource "aws_instance" "web" {
  ami           = var.aws_instance_ami_id
  instance_type = var.aws_instance_type

  tags = {
    Name = var.aws_instance_name
  }
}