provider "aws" {
  version = "~> 3.0"
  region  = var.region
}

resource aws_vpc "rabbitws" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc"
  }
}

resource aws_subnet "rabbitws" {
  vpc_id     = aws_vpc.rabbitws.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource aws_security_group "rabbitws" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.rabbitws.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource random_id "app-server-id" {
  prefix      = "${var.prefix}-rabbitws-"
  byte_length = 8
}

resource aws_internet_gateway "rabbitws" {
  vpc_id = aws_vpc.rabbitws.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource aws_route_table "rabbitws" {
  vpc_id = aws_vpc.rabbitws.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rabbitws.id
  }
}

resource aws_route_table_association "rabbitws" {
  subnet_id      = aws_subnet.rabbitws.id
  route_table_id = aws_route_table.rabbitws.id
}

data aws_ami "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_eip" "rabbitws" {
  instance = aws_instance.rabbitws.id
  vpc      = true
}

resource "aws_eip_association" "rabbitws" {
  instance_id   = aws_instance.rabbitws.id
  allocation_id = aws_eip.rabbitws.id
}

resource aws_instance "rabbitws" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.rabbitws.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.rabbitws.id
  vpc_security_group_ids      = [aws_security_group.rabbitws.id]

  tags = {
    Name = "${var.prefix}-rabbitws-instance"
  }
}

# We're using a little trick here so we can run the provisioner without
# destroying the VM. Do not do this in production.

# If you need ongoing management (Day N) of your virtual machines a tool such
# as Chef or Puppet is a better choice. These tools track the state of
# individual files and can keep them in the correct configuration.

# Here we do the following steps:
# Sync everything in files/ to the remote VM.
# Set up some environment variables for our script.
# Add execute permissions to our scripts.
# Run the deploy_app.sh script.
resource "null_resource" "configure-rabbit-ws" {
  depends_on = [aws_eip_association.rabbitws]

  triggers = {
    build_number = timestamp()
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello World'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.rabbitws.private_key_pem
      host        = aws_eip.rabbitws.public_ip
    }
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.rabbitws.private_key_pem}' > ${var.private_key_path} && chmod 600 ${var.private_key_path} && echo ${aws_eip.rabbitws.public_ip} >${var.public_dns_path}"
  }

#  provisioner "file" {
#    source      = "files/"
#    destination = "/home/ubuntu/"
#
#    connection {
#      type        = "ssh"
#      user        = "ubuntu"
#      private_key = tls_private_key.rabbitws.private_key_pem
#      host        = aws_eip.rabbitws.public_ip
#    }
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "sudo add-apt-repository universe",
#      "sudo apt -y update",
#      "sudo apt -y install apache2",
#      "sudo systemctl start apache2",
#      "sudo chown -R ubuntu:ubuntu /var/www/html",
#      "chmod +x *.sh",
#      "PLACEHOLDER=${var.placeholder} WIDTH=${var.width} HEIGHT=${var.height} PREFIX=${var.prefix} ./deploy_app.sh",
#    ]
#
#    connection {
#      type        = "ssh"
#      user        = "ubuntu"
#      private_key = tls_private_key.rabbitws.private_key_pem
#      host        = aws_eip.rabbitws.public_ip
#    }
#  }
}

resource tls_private_key "rabbitws" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}

resource aws_key_pair "rabbitws" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.rabbitws.public_key_openssh
}
