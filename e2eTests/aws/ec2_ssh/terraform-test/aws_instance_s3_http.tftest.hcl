run "http_status_check" {

  command = apply

  assert {
    condition     = output.status_code  == 200
    error_message = "the website is not up and running"
  }

}
