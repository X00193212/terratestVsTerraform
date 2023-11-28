run teraaform_public_nw{
  command = apply
  assert {
      condition     = data.aws_subnet.public.map_public_ip_on_launch == true
      error_message = "The subnet is not public."
  }
}
run teraaform_private_nw{
  command = apply
  assert {
    condition     = data.aws_subnet.private.map_public_ip_on_launch == false
    error_message = "The subnet is not public."
  }
}