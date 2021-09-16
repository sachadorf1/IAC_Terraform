# Let's set up our cloud provider with Terraform

provider "aws" {
    region = "eu-west-1"

}


# resource "aws_instance" "app_instance" {
#   ami = "ami-00e8ddf087865b27f"
#   instance_type = "t2.micro"
#   associate_public_ip_address = true
#   tags = {
#       Name = "sre_sacha_terraform_app"
#   }
#   key_name = "sre_key"
# }




# Let's start with Launching the EC2 instance using the app AMI
# define the resource name

# resource "aws_instance" "app_instance" {
#   ami = "ami-00e8ddf087865b27f"
#   vpc_id=
#   subnet=
#   sg=
#   instance_type = "t2.micro"
#   associate_public_ip_address = true
#   tags = {
#       Name = "sre_sacha_terraform_app"
#   }
# }

# ami id ` `

# `sre_key.pem` file
# AWS keys set is already done (changed in environment variables)
# public ip
# type of the instance `t2micro` 


# step 1 create a vpc with your CDIR block
# run terraform plan then terraform apply
# get the VPC ID from aws or terraform logs

resource "aws_vpc" "sre_sacha_vpc" {
  cidr_block       = "10.106.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "sre_sacha_vpc"
  }
}  

resource "aws_subnet" "sre_sacha_public" {
  vpc_id     = "vpc-0ca8e735b4084d9cc"
  cidr_block = "10.106.0.0/24"
  map_public_ip_on_launch = "true"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_public"
  }
}

# resource "aws_route_table" "public" {
# vpc_id = "${var.vpc_id}"



# route {
# cidr_block = "0.0.0.0/0"
# gateway_id = "${data.aws_internet_gateway.default.id}"
# }



# tags = {
# Name = "${var.name}-public"
# }
# }


resource "aws_security_group" "sr_sacha_app_group"  {
  name = "sre_sacha_app_sg_terraform"
  description = "sre_sacha_app_sg_terraform"
  vpc_id = "vpc-0ca8e735b4084d9cc" # attaching the SG with your own VPC
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
    cidr_blocks     = ["86.155.183.106/32"]  
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

resource "aws_internet_gateway" "sre_sacha_terraform_ig" {
  vpc_id = var.vpc_id
  tags = {
    Name = "sre_sacha_terraform_ig"
  }
}

resource "aws_route_table" "sre_sacha_rt-public" {
vpc_id = "${var.vpc_id}"
route {
cidr_block = "0.0.0.0/0"
gateway_id = "igw-0c908535cb474f16a"
}
tags = {
Name = "sre_sacha_rt-public"
}
}

resource "aws_route" "sre_sacha_route_ig_connection" {
    route_table_id = var.def_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
}




# resource "aws_internet_gateway" "sre_sacha_igw" {
#   vpc_id = "vpc-0ca8e735b4084d9cc"
#   tags = {
#     Name = "sre_sacha_igw"
#   }
# }