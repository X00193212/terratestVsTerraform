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
  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -",
      "sudo yum install -y nodejs",
      "aws configure set aws_access_key_id {access key id}",
      "aws configure set aws_secret_access_key {access key pwd}",
      "aws configure set region us-east-1",
      "bucket_name='javascript-s3-bucket'",
      "object_key='deployment-package.zip'",
      "object_exists() {",
      "  aws s3api head-object --bucket \"$bucket_name\" --key \"$object_key\" >/dev/null 2>&1",
      "  return $?",
      "}",
      "max_retries=10",
      "retry_interval=5",
      "retries=0",
      "while ! object_exists && [ $retries -lt $max_retries ]; do",
      "  echo 'Object does not exist yet, waiting...'",
      "  sleep $retry_interval",
      "  retries=$((retries + 1))",
      "done",
      "if [ $retries -eq $max_retries ]; then",
      "  echo 'Object did not exist after waiting period.'",
      "  exit 1",
      "fi",
      "echo 'Object exists! Downloading and continuing with setup.'",
      "aws s3 cp s3://javascript-s3-bucket/deployment-package.zip /home/ec2-user/",
      "unzip /home/ec2-user/deployment-package.zip -d /home/ec2-user/my-app",
      "cd /home/ec2-user/my-app",
      "npm install",
      "set -x",
      "cd /home/ec2-user/my-app",
      "echo 'Application Starting!'",
      "sudo yum install screen",
      "screen -dmS node_app bash -c 'node server.js > output.log 2>&1'",
      # Add a short delay to allow the application to start
      "ls",
      "cat /home/ec2-user/my-app/output.log",
      "sleep 5",
      "echo $! > /home/ec2-user/my-app/app.pid",    
      "set +x",  
    ]
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("path to .pem file on local")
    host = aws_eip.elasticIp.public_ip
  }
  depends_on = [ aws_instance.ec2_vm,aws_s3_bucket_object.deployment_package ]
}
resource "null_resource" "node_app_4" {
  provisioner "remote-exec" {
    inline = [ "#!/bin/bash",
     "set -x",
     "cd /home/ec2-user/my-app",
     "nohup /usr/bin/node server.js > output.log 2>&1 &",
     "echo Application is running!",
     ]
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("path to private key .pem file on local")
    host = aws_eip.elasticIp.public_ip
  }
  depends_on = [aws_eip.elasticIp]
}

data "http" request_to_website {
   url = "http://${aws_eip.elasticIp.public_ip}:3000"
   method = "HEAD"
   depends_on = [ null_resource.node_app_4 ]
}

output "instance_id" {
  value = aws_instance.ec2_vm.id
}

output "status_code" {
  value = data.http.request_to_website.status_code
}
output "vm_public_ip" {
  value = aws_eip.elasticIp.public_ip
}