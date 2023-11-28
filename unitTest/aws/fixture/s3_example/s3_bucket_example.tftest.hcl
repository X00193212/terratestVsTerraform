variables {
  bucket_name = "javascript-s3-bucket"
}

run "valid_bucket_name" {

  command = apply

  assert {
    condition     = aws_s3_bucket.example_bucket.bucket == "javascript-s3-bucket"
    error_message = "S3 bucket name did not match expected"
  }

}
