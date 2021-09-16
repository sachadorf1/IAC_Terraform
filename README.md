# Terraform Orchestration
## What is Terraform
### Why Terraform
#### Setting up Terraform
##### Securing AWS keys for Terraform


### What is Terraform?
- Open-source infrastructure as code software tool that provides a consistent Command Line Interface (CLI) workflow to manage hundreds of cloud services.

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
- ami id ` `
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

### Create a VPC

- delete your customised VPC and resources created inside the VPC
- then create a VPC with Terraform

- See [Networking documentation](https://github.com/sachadorf1/SRE_AWS_VPC_Networking) repo for setting up a VPC on AWS. We are using the same method but using Terraform.

### step 1 create a vpc with your CDIR block
- Create variable.tf folder and enter the following (using your own CIDR block e.g. 10.106.0.0/16):
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

### step 2 create a public subnet using VPC ID
- Add this to your main.tf file
```
resource "aws_subnet" "sre_sacha_public" {
  vpc_id     = "vpc-0ca8e735b4084d9cc"
  cidr_block = "10.106.0.0/24"

  tags = {
    Name = "sre_sacha_public"
  }
}
```

### Step 3 create 



## Data

Now we're building quickly. Let's add a few more parts of our architecture. For example, our subnet is currently using the default route table which is private. Let's create a new route table and associate it with our public subnet.



> EXERCISE ( 5 Minutes ) : Find the resource needed to create a route table.

```
resource "aws_route_table" "public" {
vpc_id = "${var.vpc_id}" route {
cidr_block = "0.0.0.0/0"
gateway_id = "????"
} tags = {
Name = "${var.name}-public"
}
}
```

- grab a reference to the internet gateway for our VPC
data
 "aws_internet_gateway" "default" {
filter {
name = "attachment.vpc-id"
values = ["${var.vpc_id}"]
}
}


variable "aws_key_name" {

    default = "sre_key"

}



variable "aws_key_path" {

    default = "~/.ssh/sre_key.pem"

}