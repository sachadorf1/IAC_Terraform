# Let's set up our cloud provider with Terraform
provider "aws" {
    region = "eu-west-1"

}

# vpc
resource "aws_vpc" "sre_sacha_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "sre_sacha_vpc"
  }
}  

# Creating a public subnet inside the VPC
resource "aws_subnet" "sre_sacha_subnet_public" {
  vpc_id     = aws_vpc.sre_sacha_vpc.id
  cidr_block = var.public_subnet_cidr
  map_public_ip_on_launch = "true"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_public"
  }
}

# Creating a private subnet inside the VPC
resource "aws_subnet" "sre_sacha_subnet_private" {
  vpc_id     = aws_vpc.sre_sacha_vpc.id
  cidr_block = var.private_subnet_cidr
  map_public_ip_on_launch = "false"  # Makes this a private subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_private"
  }
}

# Creating a new internet gateway attached to the VPC
resource "aws_internet_gateway" "sre_sacha_terraform_ig" {
  vpc_id = aws_vpc.sre_sacha_vpc.id
  tags = {
    Name = "sre_sacha_terraform_ig"
  }
}

resource "aws_route" "sre_sacha_route_ig_connection" {
    route_table_id = aws_vpc.sre_sacha_vpc.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sre_sacha_terraform_ig.id
}

# Creating an app Security Group attached to VPC
resource "aws_security_group" "sr_sacha_app_group"  {
  name = "sre_sacha_app_sg_terraform"
  description = "sre_sacha_app_sg_terraform"
  vpc_id = aws_vpc.sre_sacha_vpc.id # attaching the SG with your own VPC
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
    cidr_blocks     = ["${var.myip}"]  
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

# Creating an app instance, using VPC, public subnet and app security group
resource "aws_instance" "sre_sacha_terraform_app" {
  ami =  var.ami_app_id
  subnet_id = aws_subnet.sre_sacha_subnet_public.id
  vpc_security_group_ids = [aws_security_group.sr_sacha_app_group.id]
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

# Creating a db Security Group with port access for the app ip, attached to VPC
resource "aws_security_group" "sr_sacha_db_group"  {
  name = "sre_sacha_db_sg_terraform"
  description = "sre_sacha_db_sg_terraform"
  vpc_id = aws_vpc.sre_sacha_vpc.id # attaching the SG with your own VPC
  ingress {
    from_port       = "27017"
    to_port         = "27107"
    protocol        = "tcp"
    cidr_blocks     = ["${aws_instance.sre_sacha_terraform_app.public_ip}"]   
  }
  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    cidr_blocks     = ["${var.myip}"]  
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

