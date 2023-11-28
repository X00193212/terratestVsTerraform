package test

import (
	"os/exec"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestEC2WithS3AndUserData(t *testing.T) {

	terraformOptions := &terraform.Options{
		// Path to your Terraform code
		TerraformDir: "../code",

		// Variables to pass to your Terraform configuration
		Vars: map[string]interface{}{
			"user_data_script": `#!/bin/bash
				# Install node
				curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
				sudo yum install -y nodejs

				# Configure AWS CLI with IAM user credentials
				aws configure set aws_access_key_id {replace with access key}
				aws configure set aws_secret_access_key {replace with secret key}
				aws configure set region us-east-1  # Replace with the desired region

				# Download and unzip your Node.js application
				aws s3 cp s3://javascript-s3-bucket/deployment-package.zip /home/ec2-user/
				unzip /home/ec2-user/deployment-package.zip -d /home/ec2-user/my-app

				# Navigate to your application directory
				cd /home/ec2-user/my-app

				# Install application dependencies and start the Node.js application
				npm install
				node server.js
				`,
		},
	}

	// Run `terraform init` and `terraform apply`. Fail the test if there are errors.
	//defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	// Get the EIP of the EC2 instance
	eip := terraform.Output(t, terraformOptions, "vm_public_ip")
	// SSH into the EC2 instance
	cmd := exec.Command("ssh", "-o", "StrictHostKeyChecking=no", "-i", "path to .pem file on local", "ec2-user@"+eip, "curl http://localhost:3000")
	output, err := cmd.CombinedOutput()
	require.NoError(t, err)


	// Optionally, you can also use a wait loop to ensure that your application is fully started.
	maxRetries := 5
	sleepBetweenRetries := 10 * time.Second
	description := "HTTP check on the instance"

	retry.DoWithRetry(t, description, maxRetries, sleepBetweenRetries, func() (string, error) {
		cmd := exec.Command("ssh", "-o", "StrictHostKeyChecking=no", "-i", "path to .pem file on local", "ec2-user@"+eip, "curl http://localhost:3000")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return "", err
		}
		return "", nil
	})

}
