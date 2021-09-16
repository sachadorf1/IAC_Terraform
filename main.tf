# Let's set up our cloud provider with Terraform

provider "aws" {
    region = "eu-west-1"

}


# Let's start with Launching the EC2 instance using the app AMI
# define the resource name

resource "aws_instance" "app_instance" {
  ami = "ami-00e8ddf087865b27f"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  tags = {
      Name = "sre_sacha_terraform_app"
  }
}

# ami id ` `

# `sre_key.pem` file
# AWS keys set is already done (changed in environment variables)
# public ip
# type of the instance `t2micro` 