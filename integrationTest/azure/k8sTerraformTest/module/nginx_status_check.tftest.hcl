run "azurerm_kubernetes_cluster" {

  command = apply

  assert {
    condition     = azurerm_kubernetes_cluster.k8s.id != ""
    error_message = "K8s deployment is not successful!"
  }

  assert {
    condition     = null_resource.get_svc.id != ""
    error_message = "the test"
  }

  assert {
    condition = can(file("${path.module}/svc_output.txt")) && length(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", file("${path.module}/svc_output.txt"))) > 0
    error_message = "the website is not up and running"
  }

}
