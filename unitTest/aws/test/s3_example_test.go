package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

// An example of how to test the Terraform module in examples/terraform-aws-example using Terratest.
func TestTerraformS3Example(t *testing.T) {
	t.Parallel()

	// Make a copy of the terraform module to a temporary directory. This allows running multiple tests in parallel
	// against the same terraform module.
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "fixture/s3_example")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: exampleFolder,
	})

	// website::tag::4::At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// website::tag::2::Run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

    // Run `terraform output` to get the value of an output variable
    s3_bucket_tag := aws.FindS3BucketWithTag(t, "us-east-1", "Name", "javascript-s3-bucket")

    // Use the bucketName for further testing or assertions
    require.NotEmpty(t, s3_bucket_tag, "S3 bucket with the specified tag does not exist")

}
