# terratestVsTerraform
testing framework analysis

This Project is created for master's program thesis 
It consists of tests written for terraform IaC testing using Terratest and Terraform test framework

Most of the code to perform the analysis is taken from gruntwork.io's terratest github repository
Reference for below code is as follows:

unitTest
unitTest -> aws -> fixture -> S3_example : terraform code is taken from terratest repository : https://github.com/gruntwork-io/terratest/tree/master/examples/terraform-aws-s3-example
unitTest -> aws -> fixture -> terraform_ec2_aws_example : terraform code is taken from : https://github.com/gruntwork-io/terratest/tree/master/examples/terraform-aws-example
unitTest -> azure -> fixture -> terraform_acr_azure_example : https://github.com/gruntwork-io/terratest/tree/master/examples/azure/terraform-azure-acr-example

corresponding terratest test files code is also from the terratest github repo as below
unitTest -> aws -> test -> ec2Aws_test.go: https://github.com/gruntwork-io/terratest/blob/master/test/terraform_aws_example_test.go
unitTest -> aws -> test -> s3_example_test.go: https://github.com/gruntwork-io/terratest/blob/master/test/terraform_aws_s3_example_test.go
unitTest -> azure -> test -> terraform_arzure_example_acr_test.go: https://github.com/gruntwork-io/terratest/blob/master/test/azure/terraform_azure_acr_example_test.go


integrationTest
integrationTest -> aws -> fixture -> aws_network_terraform_test : https://github.com/gruntwork-io/terratest/tree/master/examples/terraform-aws-network-example
integrationTest -> azure -> fixture -> k8s : https://github.com/gruntwork-io/terratest/tree/master/examples/azure/terraform-azure-aks-example

corresponding terratest test files code is also from the terratest github repo as below
integrationTest -> aws -> aws_network_terraform_test : https://github.com/gruntwork-io/terratest/blob/master/test/terraform_aws_network_example_test.go
integrationTest -> azure -> k8s: https://github.com/gruntwork-io/terratest/blob/master/test/azure/terraform_azure_aks_example_test.go


e2eTests
e2eTests -> azure -> https://learn.microsoft.com/en-us/azure/developer/terraform/best-practices-end-to-end-testing

aws e2e example is self designed and the javascript-web-app application code was generated using chatgpt

Terraform test scripts are designed using the reference from terraform test command documentation page at:
https://developer.hashicorp.com/terraform/tutorials/configuration-language/test and https://developer.hashicorp.com/terraform/language/tests

some part of test code is generated using chatgpt.