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
resource "aws_subnet" "sre_sacha_subnet_public1" {
  vpc_id     = aws_vpc.sre_sacha_vpc.id
  cidr_block = var.public_subnet_1_cidr
  map_public_ip_on_launch = "true"  # Makes this a public subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "sre_sacha_subnet_public"
  }
}

resource "aws_subnet" "sre_sacha_subnet_public2" {
  vpc_id     = aws_vpc.sre_sacha_vpc.id
  cidr_block = var.public_subnet_2_cidr
  map_public_ip_on_launch = "true"  # Makes this a public subnet
  availability_zone = "eu-west-1b"

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
  subnet_id = aws_subnet.sre_sacha_subnet_public1.id
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
    cidr_blocks     = ["${aws_instance.sre_sacha_terraform_app.public_ip}/32"]   
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
  subnet_id = aws_subnet.sre_sacha_subnet_private.id
  vpc_security_group_ids = [aws_security_group.sr_sacha_db_group.id]
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




# Creating a launch template
resource "aws_launch_template" "sre_sacha_launch_template_terraform" {
  name = "sre_sacha_launch_template_terraform"
  description = "sre_sacha_launch_template_terraform"

  image_id = var.ami_app_id

  instance_type = "t2.micro"

  key_name = var.aws_key_name

  vpc_security_group_ids = [aws_security_group.sr_sacha_app_group.id]
  tags = {
      Name = "sre_sacha_launch_template_terraform"
  }
}

# Application Load Balancer

resource "aws_lb" "sre-sacha-lb-terraform" {
  name               = "sre-sacha-lb-terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sr_sacha_app_group.id]
  subnets            = [aws_subnet.sre_sacha_subnet_public1.id, aws_subnet.sre_sacha_subnet_public2.id]

  # enable_deletion_protection = true

  tags = {
    Name = "sre-sacha-lb-terraform"
  }
}

# Target group

resource "aws_lb_target_group" "sre-sacha-lb-target-group-tf" {
  name     = "sre-sacha-lb-target-group-tf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sre_sacha_vpc.id
  
  tags = {
    Name = "sre-sacha-lb-target-group-tf"
  }
}

# Listener

resource "aws_lb_listener" "sre_sacha_lb_listener_terraform" {
  load_balancer_arn = aws_lb.sre-sacha-lb-terraform.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sre-sacha-lb-target-group-tf.arn
  }
}

# Create Auto Scaling Group from launch template
resource "aws_autoscaling_group" "sre_sacha_autoscale_terraform" {
  name = "sre_sacha_autoscale_terraform"
  vpc_zone_identifier = [aws_subnet.sre_sacha_subnet_public1.id, aws_subnet.sre_sacha_subnet_public2.id]
  desired_capacity   = 1
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = aws_launch_template.sre_sacha_launch_template_terraform.id
    version = "$Latest"
  }
}

# Auto Scaling Policy
# CPU Scale Out
resource "aws_autoscaling_policy" "sre_sacha_scale_out_CPU_policy_terraform" {
  name = "sre_sacha_scale_out_CPU_policy_terraform"
  policy_type = "TargetTrackingScaling"
  estimated_instance_warmup = 100
  autoscaling_group_name = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
  target_tracking_configuration {
      predefined_metric_specification {
          predefined_metric_type = "ASGAverageCPUUtilization"
      }
      target_value = 50.0
  }
}

# CPU Scale In
resource "aws_autoscaling_policy" "sre_sacha_scale_in_CPU_policy" {
  name                   = "sre_sacha_scale_in_CPU_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
}

# Alarm for CPU Scale In
resource "aws_cloudwatch_metric_alarm" "SRE_sacha_CPU_scale_in_alarm" {
  alarm_name          = "SRE_sacha_CPU_scale_in_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.sre_sacha_scale_in_CPU_policy.arn]
}

# Network In - Scale Out Policy
resource "aws_autoscaling_policy" "sre_sacha_scale_out_Network_In_policy" {
  name = "sre_sacha_scale_out_Network_In_policy"
  policy_type = "TargetTrackingScaling"
  estimated_instance_warmup = 100
  autoscaling_group_name = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
  target_tracking_configuration {
      predefined_metric_specification {
          predefined_metric_type = "ASGAverageNetworkIn"
      }
      target_value = 1000000
  }
}

# Network In - Scale In Policy
resource "aws_autoscaling_policy" "sre_sacha_scale_in_Network_In_policy" {
  name                   = "sre_sacha_scale_in_Network_In_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
}

# Alarm for Network In - Scale In Policy
resource "aws_cloudwatch_metric_alarm" "SRE_sacha_Network_In_scale_in_alarm" {
  alarm_name          = "SRE_sacha_Network_In_scale_in_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ASGAverageNetworkIn"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1000000"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
  }

  alarm_description = "This metric monitors ec2 Total Network In"
  alarm_actions     = [aws_autoscaling_policy.sre_sacha_scale_in_Network_In_policy.arn]
}


# resource "aws_autoscaling_policy" "sre_sacha_scale_out_ALB_Request_policy" {
#   name = "sre_sacha_scale_out_ALB_Request_policy"
#   policy_type = "TargetTrackingScaling"
#   estimated_instance_warmup = 100
#   autoscaling_group_name = aws_autoscaling_group.sre_sacha_autoscale_terraform.name
#   target_tracking_configuration {
#       predefined_metric_specification {
#           predefined_metric_type = "ALBRequestCountPerTarget"
#       }
#       target_value = 50.0
#   }
# }