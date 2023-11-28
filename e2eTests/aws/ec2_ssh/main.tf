provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "javascript-s3-bucket"  # Replace with your desired S3 bucket name
  acl    = "private"  # You can set the appropriate ACL here
   tags = {
    "Name"        = "javascript-s3-bucket"
  }
}

# Create a new IAM policy that allows the user to access the S3 bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "IAM policy for S3 access"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.example_bucket.arn,
          "${aws_s3_bucket.example_bucket.arn}/*",
        ],
      },
    ],
  })
}
variable "existing_iam_user_name" {
  description = "Name of the existing IAM user to which the policy will be attached"
  type        = string
  default     = "project2023"  # Replace with the IAM user name
}

# Attach the IAM policy to the IAM user
resource "aws_iam_policy_attachment" "example_user_attachment" {
  name       = "example_user_attachment"
  policy_arn = aws_iam_policy.s3_access_policy.arn
  users      = [var.existing_iam_user_name]
}


output "s3_bucket_name" {
  value = aws_s3_bucket.example_bucket.id
}

data "archive_file" "source_code" {
  type        = "zip"
  source_dir  = "${path.module}/javascript"
  output_path = "${path.module}/deployment-package.zip"
}

resource "aws_s3_bucket_object" "deployment_package" {
  bucket = aws_s3_bucket.example_bucket.id
  key    = "deployment-package.zip"
  source = "${path.module}/deployment-package.zip"
  content_type = "application/zip"
}

#ec2

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "webappVpc"
  cidr = "10.0.0.0/16"
  azs = [
    "us-east-1a"]
  public_subnets = [
    "10.0.101.0/24"]
}
resource "aws_security_group" "app_sec_grp" {
  name = "allow_http_traffic"
  description = "allow http,https traffic through tcp and ssh"
  vpc_id = module.vpc.vpc_id
    # Ingress rule for port 3000 (Node.js application)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}
resource "aws_instance" "ec2_vm" {
  ami = "ami-041feb57c611358bd"
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.app_sec_grp.id]
  key_name = "project2023"
  associate_public_ip_address = true
 
  tags = {
    Name = "terratest-aws-s3-example-90"
  }
}
resource "aws_eip" "elasticIp" {
  instance = aws_instance.ec2_vm.id
}

output "instance_id" {
  value = aws_instance.ec2_vm.id
}

output "vm_public_ip" {
  value = aws_eip.elasticIp.public_ip
}