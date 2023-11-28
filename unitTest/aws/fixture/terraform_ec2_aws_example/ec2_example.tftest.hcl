variables {
  instance_name = "testing-tag-value"
  instance_type = "t2.micro"
}

run "verifyTag" {

  command = apply

  assert {
    condition     = aws_instance.example.tags.Name == "testing-tag-value"
    error_message = "aws instance don't exists"
  }

}
