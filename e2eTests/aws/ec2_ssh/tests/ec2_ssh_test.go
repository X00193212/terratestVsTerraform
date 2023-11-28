package tests

import (
	"crypto/tls"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformAwsSShExample(t *testing.T) {
	logFile, err := os.Create("console_output.txt")
	if err != nil {
		log.Fatal("Error creating log file: ", err)
	}
	defer logFile.Close()
	log.SetOutput(logFile)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",
	})
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "instance_id")
	publicInstanceIP := terraform.Output(t, terraformOptions, "vm_public_ip")

	fmt.Println(instanceID)
	privateKeyPath := "path to private key .pem file on local"

	// Read the private key from the file
	privateKeyBytes, err := ioutil.ReadFile(privateKeyPath)
	if err != nil {
		t.Fatal(err)
	}

	// Create an ssh.KeyPair object with the private key
	keyPair := &ssh.KeyPair{
		PrivateKey: string(privateKeyBytes),
	}

	publicHost := ssh.Host{
		Hostname:    publicInstanceIP,
		SshKeyPair:  keyPair,
		SshUserName: "ec2-user",
		SshAgent:    false,
	}
	script := `#!/bin/bash
    # Install Node.js
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
	
	
    # Configure AWS CLI with IAM user credentials
    aws configure set aws_access_key_id {replace with aws_access_key_id}
    aws configure set aws_secret_access_key {replace with aws_secret_access_key}
    aws configure set region us-east-1  # Replace with the desired region

    # Download and unzip your Node.js application
    aws s3 cp s3://javascript-s3-bucket/deployment-package.zip /home/ec2-user/
    unzip /home/ec2-user/deployment-package.zip -d /home/ec2-user/my-app

    # Navigate to your application directory
    cd /home/ec2-user/my-app
	
	npm install
	nohup node server.js > output.log 2>&1 &
	echo Application Running!`

	command := `echo '` + script + `' > script.sh && chmod +x script.sh && ./script.sh`
	time.Sleep(60 * time.Second)

	output, err := ssh.CheckSshCommandE(t, publicHost, command)

	if err != nil {
		t.Fatalf("Error executing SSH command: %v", err)
	}
	fmt.Printf("This is the: %v", output)

	// Set the log output to both stdout and the log file

	log.Println(output)
	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// It can take a minute or so for the Instance to boot up, so retry a few times
	maxRetries := 5
	timeBetweenRetries := 5 * time.Second
	instanceURL := "http://" + publicInstanceIP + ":3000"

	content, err := ioutil.ReadFile("template.html")
	if err != nil {
		fmt.Printf("Error reading the file: %v\n", err)
		return
	}

	// Convert the content to a string.
	instanceText := string(content)

	fmt.Println("New implementation before termination")
	http_helper.HttpGetWithRetry(t, instanceURL, &tlsConfig, 200, instanceText, maxRetries, timeBetweenRetries)

}
