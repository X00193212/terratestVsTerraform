provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "${var.bucket_name}"  # Replace with your desired S3 bucket name
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