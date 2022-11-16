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
variable "number_of_stduents" {
  type    = number
  default = 1
}

# IAM
resource "aws_iam_user" "instructor" {
  name = "instructor"
}

resource "aws_iam_user" "student" {
  count = var.number_of_stduents

  name = "student${count.index + 1}"
}

resource "aws_iam_user_policy_attachment" "instructor" {
  user       = aws_iam_user.instructor.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloud9User"
}

resource "aws_iam_user_policy_attachment" "student" {
  count = var.number_of_stduents

  user       = aws_iam_user.student[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloud9User"
}

resource "aws_iam_user_login_profile" "instructor" {
  user                    = aws_iam_user.instructor.name
  password_reset_required = false
}

resource "aws_iam_user_login_profile" "student" {
  count = var.number_of_stduents

  user                    = aws_iam_user.student[count.index].name
  password_reset_required = false
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

# Cloud9
resource "aws_cloud9_environment_ec2" "instructor" {
  instance_type = "t3.small"
  name          = "instructor"
  owner_arn     = aws_iam_user.instructor.arn
  subnet_id     = aws_subnet.this.id

  automatic_stop_time_minutes = 30
}

resource "aws_cloud9_environment_ec2" "student" {
  count = var.number_of_stduents

  instance_type = "t3.small"
  name          = aws_iam_user.student[count.index].name
  owner_arn     = aws_iam_user.student[count.index].arn
  subnet_id     = aws_subnet.this.id

  automatic_stop_time_minutes = 30
}

# EC2
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

resource "aws_instance" "instructor_cp" {
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
adduser --quiet --disabled-password --shell /bin/bash --home /home/student --gecos 'Student' student
echo 'student:asdf1234' | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
usermod -aG sudo student
echo 'student ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
apt update && apt install -y jq
EOF

  tags = {
    Name = "instructor_cp"
  }
}

resource "aws_instance" "student_cp" {
  count = var.number_of_stduents

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
adduser --quiet --disabled-password --shell /bin/bash --home /home/student --gecos 'Student' student
echo 'student:asdf1234' | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
usermod -aG sudo student
echo 'student ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
apt update && apt install -y jq
EOF

  tags = {
    Name = "student${count.index + 1}_cp"
  }
}

resource "aws_instance" "instructor_worker" {
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
adduser --quiet --disabled-password --shell /bin/bash --home /home/student --gecos 'Student' student
echo 'student:asdf1234' | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
usermod -aG sudo student
echo 'student ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

  tags = {
    Name = "instructor_worker"
  }
}

resource "aws_instance" "student_worker" {
  count = var.number_of_stduents

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
adduser --quiet --disabled-password --shell /bin/bash --home /home/student --gecos 'Student' student
echo 'student:asdf1234' | chpasswd
sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
systemctl restart sshd
usermod -aG sudo student
echo 'student ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

  tags = {
    Name = "student${count.index + 1}_worker"
  }
}

# Output
output "instructor_password" {
  value = aws_iam_user_login_profile.instructor.password
}

output "student_password" {
  value = {
    for lp in aws_iam_user_login_profile.student : lp.user => lp.password
  }
}

output "instructor_instances" {
  value = {
    cp     = aws_instance.instructor_cp.public_ip
    worker = aws_instance.instructor_worker.public_ip
  }
}

output "student_instances" {
  value = {
    for k, student in aws_iam_user.student : student.name => {
      cp     = aws_instance.student_cp[k].public_ip
      worker = aws_instance.student_worker[k].public_ip
    }
  }
}