# Terraform Orchestration
## What is Terraform
### Why Terraform
#### Setting up Terraform
##### Securing AWS keys for Terraform

![](img/terraform_with_ansible.jpg)

### What is Terraform?
- Open-source infrastructure as code software tool that provides a consistent Command Line Interface (CLI) workflow to manage hundreds of cloud services.

### Why Terraform?

### `terraform init`
- 

### `terraform plan`
- Creates an execution plan
- Comparing the current configuration to the prior state and noting any differences.
### `terraform apply`
- Executes the actions proposed in a Terraform plan

### `terraform destroy`
- Destroys all remote objects managed by a particular Terraform configuration
- terraform apply -destroy

### Setting up Terraform
- Create env var to secure AWS keys
    - In Windows, `Edit the system environment variables` -> `Advanced` -> `Environment Variables...` -> Under `User variables for Sacha`, click `New...`
    - Variable Name: AWS_ACCESS_KEY_ID -> Variable Value: (copy value from excel file)
    - Variable Name: AWS_SECRET_ACCESS_KEY -> Variable Value: (copy value from excel file)
- Restart the terminal
- Create a file called main.tf
- add the code to initialise terrafrom with provider AWS

```
provider "aws" {
    region = "eu-west-1"

}
```

- Let's run this code with `terraform init`

### Creating Resources on AWS
- Let's start with Launching the EC2 instance using the app AMI
    - define the resource name
    - ami id
    - `sre_key.pem` file
    - AWS keys set is already done (changed in environment variables)
    - public ip
    - type of the instance `t2micro` 

```
resource "aws_instance" "app_instance" {
  ami = "ami-00e8ddf087865b27f"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  tags = {
      Name = "sre_sacha_terraform_app"
  }
}
```

- `terraform plan`
- `terraform apply` -> `yes`

- Instance should be running

- `terraform destroy` to delete instance you have created

## Create a VPC

![](img/AWS_deployment_networking_security.png)

- delete your customised VPC and resources created inside the VPC
- then create a VPC with Terraform

- See [Networking documentation](https://github.com/sachadorf1/SRE_AWS_VPC_Networking) repo for setting up a VPC on AWS. We are using the same method but using Terraform.

### Create a vpc with your CDIR block
- Create variable.tf folder - This is where you can define variables for your vpc id, subnet id, security groups etc so you can use the variable names in your main.tf file, rather than the actual ids
- In your main.tf folder, enter the following using your own CIDR block (e.g. 10.106.0.0/16):
```
resource "aws_vpc" "main" {
  cidr_block       = "10.106.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}  
```
- Run `terraform plan`
- Run `terraform apply`

- get the VPC ID from aws or terraform logs
- add the VPC ID to your variable.tf file e.g.
```
variable "vpc_id" {
  default = "vpc-0ca8e735b4084d9cc"
}
```
- Now you can write var.vpc_id to get the id of your vpc

- Also add vpc_cidr (e.g. 10.106.0.0/16), public_subnet_cidr (e.g. 10.106.1.0/24), ami_app_id (Use the ami you previously created for your app), aws_key_name, aws_key_path to the variable.tf file in the same way as you did with the vpc_id
```
variable "aws_key_name" {
    default = "sre_key"
}
```
```
variable "aws_key_path" {
    default = "~/.ssh/sre_key.pem"
}
```
### Create a public subnet using your VPC ID
- Add the following to your main.tf file:
```
resource "aws_subnet" "sre_sacha_subnet_public" {
  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = "true"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_public"
  }
}
```

- Add subnet_public_id to variable.tf

### Create an internet gateway using your VPC ID
- Add the following to your main.tf file:
```
resource "aws_internet_gateway" "sre_sacha_terraform_ig" {
  vpc_id = var.vpc_id
  tags = {
    Name = "sre_sacha_terraform_ig"
  }
}
```
- Add internet_gateway_id to variable.tf file

## Data

Now we're building quickly. Let's add a few more parts of our architecture. For example, our subnet is currently using the default route table which is private. Let's create a new route table and associate it with our public subnet.



> EXERCISE ( 5 Minutes ) : Find the resource needed to create a route table.

### Create a new route table, attach using internet gateway
- Add the following to your main.tf file:
```
resource "aws_route_table" "sre_sacha_rt-public" {
vpc_id = var.vpc_id
route {
cidr_block = "0.0.0.0/0"
gateway_id = var.internet_gateway_id
}
tags = {
Name = "sre_sacha_rt-public"
}
}
```
- Add def_route_table_id to variable.tf file
### Grab a reference to the internet gateway for our VPC
- Add the following to your main.tf file:
```
data
 "aws_internet_gateway" "default" {
filter {
name = "attachment.vpc-id"
values = ["${var.vpc_id}"]
}
}
```
### Creating a Security Group attached to your VPC
- Add the following to your main.tf file, making sure to enter you ip address for port 22 access:

```
resource "aws_security_group" "sr_sacha_app_group"  {
  name = "sre_sacha_app_sg_terraform"
  description = "sre_sacha_app_sg_terraform"
  vpc_id = var.vpc_id # attaching the SG with your own VPC
  ingress {
    from_port       = "80"
    to_port         = "80"
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]   
  }
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    cidr_blocks     = ["enter you ip address here"]  
  }
    ingress {
    from_port       = "3000"
    to_port         = "3000"
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]  
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1" # allow all
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sre_sacha_app_sg_terraform"
  }
}
```
- Add security_group_id to variable.tf file 

### Create an EC2 instance for your app
- Add the following to your main.tf file:
```
resource "aws_instance" "sre_sacha_terraform_app" {
  ami =  var.ami_id
  subnet_id = var.subnet_public_id
  vpc_security_group_ids = [var.security_group_id]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = var.aws_key_name
  connection {
		type = "ssh"
		user = "ubuntu"
		private_key = var.aws_key_path
		host = "${self.associate_public_ip_address}"
	} 
  tags = {
      Name = "sre_sacha_terraform_app"
  }
}
```
- You should see your app instance in AWS
## For your DB:
- Same vpc_id
- Create a private subnet with private subnet CIDR
- In variable.tf
    - Add the ami_db_id (Use the ami you created previously for your db)
    - Add the private_subnet_cidr (e.g. 10.106.2.0/24)
### Create a private subnet
- Add the following to your main.tf file:
```
resource "aws_subnet" "sre_sacha_subnet_private" {
  vpc_id     = var.vpc_id
  cidr_block = var.private_subnet_cidr
  map_public_ip_on_launch = "false"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_private"
  }
}
```
- `terraform plan`
- `terraform apply`
- Add subnet_private_id to variable.tf

### Create a db security group attached to the VPC
- Add the following to your main.tf file:
- Use the app ip from 
```
resource "aws_security_group" "sr_sacha_db_group"  {
  name = "sre_sacha_db_sg_terraform"
  description = "sre_sacha_db_sg_terraform"
  vpc_id = var.vpc_id # attaching the SG with your own VPC
  ingress {
    from_port       = "27017"
    to_port         = "27107"
    protocol        = "tcp"
    cidr_blocks     = ["enter your app ip here"]   
  }
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    cidr_blocks     = ["86.155.183.106/32"]  
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1" # allow all
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sre_sacha_db_sg_terraform"
  }
}
```
- Add security_group_db_id to the variable.tf file
- `terraform plan`
- `terraform apply`
### Creating a db instance

```
resource "aws_instance" "sre_sacha_terraform_db" {
  ami =  var.ami_db_id
  subnet_id = var.subnet_private_id
  vpc_security_group_ids = [var.security_group_db_id]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = var.aws_key_name
  connection {
		type = "ssh"
		user = "ubuntu"
		private_key = var.aws_key_path
		host = "${self.associate_public_ip_address}"
        # host = aws_instance.app_instance.public_ip
	} 
  tags = {
      Name = "sre_sacha_terraform_db"
  }
}
```
- `terraform plan`
- `terraform apply`
- You should see your db instance in AWS (and be able to ssh into it if you have given yourself port 22 access)