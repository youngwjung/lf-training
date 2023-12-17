# Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# Variable
variable "nfs" {
  type    = bool
  default = true
}

variable "ha" {
  type    = bool
  default = true
}

# Network
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

data "aws_availability_zones" "azs" {}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = aws_vpc.this.cidr_block
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
}

resource "aws_route" "internet" {
  route_table_id         = aws_vpc.this.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# EC2
resource "random_password" "this" {
  length  = 8
  special = false
}

resource "aws_security_group" "this" {
  name        = "lab-instance-sg"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "cp" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  root_block_device {
    volume_size = 20
  }
  subnet_id = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname cp
echo "root:${random_password.this.result}" | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
apt update && apt install -y jq
EOF

  tags = {
    Name = "cp"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  root_block_device {
    volume_size = 20
  }
  subnet_id = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname worker
echo "root:${random_password.this.result}" | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
EOF

  tags = {
    Name = "worker"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "nfs" {
  count = var.nfs ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  root_block_device {
    volume_size = 20
  }
  subnet_id = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname nfs
echo "root:${random_password.this.result}" | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
EOF

  tags = {
    Name = "nfs"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "haproxy" {
  count = var.ha ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  root_block_device {
    volume_size = 20
  }
  subnet_id = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname haproxy
echo "root:${random_password.this.result}" | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
EOF

  tags = {
    Name = "haproxy"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "secondcp" {
  count = var.ha ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  root_block_device {
    volume_size = 20
  }
  subnet_id = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname secondcp
echo "root:${random_password.this.result}" | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
EOF

  tags = {
    Name = "secondcp"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "thirdcp" {
  count = var.ha ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  root_block_device {
    volume_size = 20
  }
  subnet_id = aws_subnet.this.id
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname thirdcp
echo "root:${random_password.this.result}" | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
EOF

  tags = {
    Name = "thirdcp"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Output
output "instances" {
  value = {
    cp       = aws_instance.cp.public_ip
    worker   = aws_instance.worker.public_ip
    nfs      = var.nfs ? aws_instance.nfs[0].public_ip : null
    haproxy  = var.ha ? aws_instance.haproxy[0].public_ip : null
    secondcp = var.ha ? aws_instance.secondcp[0].public_ip : null
    thirdcp  = var.ha ? aws_instance.thirdcp[0].public_ip : null
  }
}

output "ssh_password" {
  value = nonsensitive(random_password.this.result)
}