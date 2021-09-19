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


# ami id ` `

# `sre_key.pem` file
# AWS keys set is already done (changed in environment variables)
# public ip
# type of the instance `t2micro` 


# step 1 create a vpc with your CDIR block
# run terraform plan then terraform apply
# get the VPC ID from aws or terraform logs

resource "aws_vpc" "sre_sacha_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "sre_sacha_vpc"
  }
}  

resource "aws_subnet" "sre_sacha_subnet_public" {
  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = "true"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_public"
  }
}

# resource "aws_route_table" "public" {
# vpc_id = "${var.vpc_id}"



resource "aws_subnet" "sre_sacha_subnet_private" {
  vpc_id     = var.vpc_id
  cidr_block = var.private_subnet_cidr
  map_public_ip_on_launch = "false"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_private"
  }
}


# route {
# cidr_block = "0.0.0.0/0"
# gateway_id = "${data.aws_internet_gateway.default.id}"
# }



# tags = {
# Name = "${var.name}-public"
# }
# }

# Creating an app Security Group attached to VPC
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

# Creating a db Security Group with port access for the app ip, attached to VPC
resource "aws_security_group" "sr_sacha_db_group"  {
  name = "sre_sacha_db_sg_terraform"
  description = "sre_sacha_db_sg_terraform"
  vpc_id = var.vpc_id # attaching the SG with your own VPC
  ingress {
    from_port       = "27017"
    to_port         = "27107"
    protocol        = "tcp"
    cidr_blocks     = ["54.229.6.209/32"]   
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


# Creating a new internet gateway attached to the VPC
resource "aws_internet_gateway" "sre_sacha_terraform_ig" {
  vpc_id = var.vpc_id
  tags = {
    Name = "sre_sacha_terraform_ig"
  }
}

# Creating a new route table, attach using internet gateway
# resource "aws_route_table" "sre_sacha_rt-public" {
# vpc_id = var.vpc_id
# route {
# cidr_block = "0.0.0.0/0"
# gateway_id = var.internet_gateway_id
# }
# tags = {
# Name = "sre_sacha_rt-public"
# }
# }

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_route" "sre_sacha_route_ig_connection" {
    route_table_id = var.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
}




# resource "aws_internet_gateway" "sre_sacha_igw" {
#   vpc_id = "vpc-0ca8e735b4084d9cc"
#   tags = {
#     Name = "sre_sacha_igw"
#   }
# }

resource "aws_instance" "sre_sacha_terraform_app" {
  ami =  var.ami_app_id
  subnet_id = var.subnet_public_id
  vpc_security_group_ids = [var.security_group_app_id]
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
      Name = "sre_sacha_terraform_app"
  }
}

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

