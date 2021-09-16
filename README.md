# Terraform Orchestration
## What is Terraform
### Why Terraform
#### Setting up Terraform
##### Securing AWS keys for Terraform

- Create instances using VPCs you created last

- terraform plan
- terraform apply
- terraform destroy

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