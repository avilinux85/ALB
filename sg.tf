variable "sg_ports" {
  type    = list(number)
  default = [80, 443]
}


resource "aws_security_group" "SG_LB" {
  name        = "SG_LB"
  description = "SG for Load Balancer"

  dynamic "ingress" {
    for_each = var.sg_ports
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = upper("sg_lb")
  }
}


data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

output "subnet_apsouth1a" {
	value = sort(data.aws_subnets.all.ids)[0]
}

output "subnet_apsouth1b" {
  value = sort(data.aws_subnets.all.ids)[2]
}

data "aws_ami" "ami_data" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


resource "aws_instance" "lb1_ec2" {
  ami = data.aws_ami.ami_data.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG_LB.id]
  subnet_id = sort(data.aws_subnets.all.ids)[0]
  user_data = <<-EOF
  #!/bin/bash
  sudo su
  yum update -y
  yum install httpd -y
  systemctl start httpd
  systemctl enable httpd
  echo `hostname` > /var/www/html/index.html
  echo "started HTTPD service  successfully"
EOF
tags = {
  Name = "LB1_EC2"
}
}


resource "aws_instance" "lb2_ec2" {
  ami = data.aws_ami.ami_data.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG_LB.id]
  subnet_id = sort(data.aws_subnets.all.ids)[1]
  user_data = <<EOF
  #!/bin/bash
  sudo su
  yum update -y
  yum install httpd -y
  systemctl start httpd
  systemctl enable httpd
  echo `hostname` > /var/www/html/index.html
  echo "started HTTPD service  successfully"
EOF
tags = {
  Name = "LB2_EC2"
}
}
