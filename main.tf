provider "aws" {
    region = "us-east-1"
}
resource "aws_key_pair" "key_value" {
   key_name = "terraform_demo_project"
   public_key = file("C:/Users/Anubhav/.ssh/id_rsa.pub")
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

# creation of route table for public subnet with default route to the internet gateway

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.my_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW.id
    }
    tags = {
      Name = "public-rt"
    }
}

resource "aws_route_table_association" "public_rt_assosciate" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_security_group" "my_web" {
  # ... other configuration ...
   vpc_id = aws_vpc.my_vpc.id
   

   ingress {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

   ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_instance" "my_server" {
    ami = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"
    key_name = aws_key_pair.key_value.key_name
    vpc_security_group_ids = [aws_security_group.my_web.id]
    subnet_id = aws_subnet.public_subnet.id

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("C:/Users/Anubhav/.ssh/id_rsa")
      host = self.public_ip
    }


# File provisioner to copy file from local to remote EC2 instance

provisioner "file" {
    source = "Project.html"
    destination = "/home/ubuntu/Project.html"
}

provisioner "remote-exec" {
    inline = [
     "echo 'Hello from remote instance'" ,
     "sudo apt update -y",
     "sudo apt-get install -y apache2",
     "cd /home/ubuntu",
     "sudo systemctl start apache2",
     "sudo systemctl enable apache2",
     "sudo cp Project.html /var/www/html/index.html"
    ]
    }
}