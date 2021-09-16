# Terraform Orchestration
## What is Terraform
### Why Terraform
#### Setting up Terraform
##### Securing AWS keys for Terraform


### What is Terraform
- Open-source infrastructure as code software tool that provides a consistent Command Line Interface (CLI) workflow to manage hundreds of cloud services.


### `terraform plan`
- Creates an execution plan
- Comparing the current configuration to the prior state and noting any differences.
### `terraform apply`
- Executes the actions proposed in a Terraform plan

### `terraform destroy`
- Destroys all remote objects managed by a particular Terraform configuration
- terraform apply -destroy

### Tasks

- Create env var to secure AWS keys
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