/*# Initiate aws provider
provider "aws" {
  region = var.region
  access_key = "**********"
  secret_key = "**********"
}
*/

/*
Create VPC
AWS Virtual Private Cloud (VPC) is a logically isolated section of the AWS Cloud where users can 
launch AWS resources in a virtual network defined by their own IP address range, subnets, route tables, 
and security settings, providing control and customization over network configuration.
*/
resource "aws_vpc" "production_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "Production VPC"
  }
}

/*
Create the Internet Gateway
AWS Internet Gateway is a horizontally scalable, highly available AWS-managed component that allows communication 
between instances in a Virtual Private Cloud (VPC) and the internet, enabling outbound and inbound traffic to and 
from the internet for resources within the VPC.
*/
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.production_vpc.id
}

/*
Creating an elastic IP to associate with NAT gateway
AWS Elastic IP is a static IPv4 address designed for dynamic cloud computing, allowing users to easily associate and 
disassociate the address from instances, providing flexibility and facilitating seamless infrastructure changes within AWS.
*/
resource "aws_eip" "nat_eip" {
  depends_on = [ aws_internet_gateway.igw ]
}

/*
Create NAT Gateway
NAT Gateway is a managed network address translation service that enables instances within a private subnet of a 
Virtual Private Cloud (VPC) to initiate outbound communication with the internet while maintaining security and 
privacy by using a static public IP address.
*/

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet1.id
  tags = {
    Name = "NAT Gateway"
  }
}

/*
Create route tables
In AWS, a Route Table is a vital networking resource within an Amazon VPC that defines the rules, or routes, for directing network traffic. 
Each route specifies a destination IP range and a target, such as an internet gateway, virtual private gateway, network interface, or NAT gateway. 
Every VPC has a main route table by default, with subnets either explicitly associated with specific route tables or defaulting to the main one. 
Route tables are crucial for managing traffic flow in scenarios like public subnets (with internet access), private subnets (without direct internet access), 
and VPN-only subnets (for secure connections to on-premises networks). 
*/

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.production_vpc.id
  route {
    cidr_block = var.all_cidr
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public RT"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.production_vpc.id
  route {
    cidr_block = var.all_cidr
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "Private RT"
  }
}

/*
Create subnets
a subnet is a subdivision of an Amazon Virtual Private Cloud (VPC) that allows you to segment the IP address range of the VPC into smaller, more manageable chunks. 
Each subnet resides within a single Availability Zone, providing isolation and redundancy within that zone. Subnets can be designated as either public or private, 
depending on their routing configuration. Public subnets have routes to an Internet Gateway, enabling instances within them to communicate with the internet, 
while private subnets do not, enhancing security for internal resources. Subnets facilitate efficient and organized network management, allowing for better control over traffic flow, 
resource allocation, and security within the VPC.
*/

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.production_vpc.id
  cidr_block = var.public_subnet1_cidr
  availability_zone = var.availability_zone1
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet 1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.production_vpc.id
  cidr_block = var.public_subnet2_cidr
  availability_zone = var.availability_zone2
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet 2"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.production_vpc.id
  cidr_block = var.private_subnet_cidr
  availability_zone = var.availability_zone2
  tags = {
    Name = "Private subnet"
  }
}

# associate route tables with subnets
resource "aws_route_table_association" "public_association1" {
  subnet_id = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_association2" {
  subnet_id = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Create Jenkins security group
resource "aws_security_group" "jenkins_sg" {
  name = "Jenkins SG"
  description = "Allow ports 8080 and 22"
  vpc_id = aws_vpc.production_vpc.id

  ingress {
    description = "Jenkins"
    from_port = var.jenkins_port
    to_port = var.jenkins_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins SG"
  }

}

# Create  Sonarqube security group
resource "aws_security_group" "sonarqube_sg" {
  name = "Sonarqube SG"
  description = "Allow port 9000 and 22"
  vpc_id = aws_vpc.production_vpc.id

  ingress {
    description = "Sonarqube"
    from_port = var.sonarqube_port
    to_port = var.sonarqube_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sonarqube SG"
  }

}

# Create Ansible security group
resource "aws_security_group" "ansible_sg" {
  name = "Ansible SG"
  description = "Allow ports 22"
  vpc_id = aws_vpc.production_vpc.id

  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Ansible SG"
  }

}

# Create Grafana security group
resource "aws_security_group" "grafana_sg" {
  name = "Grafana SG"
  description = "Allow ports 3000 and 22"
  vpc_id = aws_vpc.production_vpc.id

  ingress {
    description = "Grafana"
    from_port = var.grafana_port
    to_port = var.grafana_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Grafana SG"
  }

}

# Create Application security group
resource "aws_security_group" "app_sg" {
  name = "Application SG"
  description = "Allow ports 80 and 22"
  vpc_id = aws_vpc.production_vpc.id

  ingress {
    description = "HTTP"
    from_port = var.http_port
    to_port = var.http_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Application SG"
  }

}

# Create LoadBalancer security group
resource "aws_security_group" "lb_sg" {
  name = "LoadBalancer SG"
  description = "Allow ports 80"
  vpc_id = aws_vpc.production_vpc.id

  ingress {
    description = "LoadBalancer"
    from_port = var.http_port
    to_port = var.http_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "LoadBalancer SG"
  }

}

/*
Create Access Control list (ACL)
an Access Control List (ACL) is a set of rules that acts as a stateless network filter controlling inbound and outbound traffic to and from one or more subnets within a Virtual Private Cloud (VPC). 
Each ACL rule specifies a protocol, a range of IP addresses or CIDR block, and whether to allow or deny traffic that matches these criteria. 
Unlike security groups, which are stateful and track the state of connections, ACLs evaluate each request independently, offering an additional layer of security by controlling traffic at the subnet level. 
They are particularly useful for implementing network-level security policies and managing traffic flow more granularly across different subnet configurations.
*/

resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.production_vpc.id
  subnet_ids = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id, aws_subnet.private_subnet.id] # If can not acess with broswer (HTTP port 80) or SSH port 22 then comment this line.

  egress {
    protocol = "tcp"
    rule_no = "100"
    action = "allow"
    cidr_block = var.vpc_cidr
    from_port = 0
    to_port = 0
  }

  ingress {
    protocol = "tcp"
    rule_no = "100"
    action = "allow"
    cidr_block = var.all_cidr
    from_port = var.http_port
    to_port = var.http_port
  }

  ingress {
    protocol = "tcp"
    rule_no = "101"
    action = "allow"
    cidr_block = var.all_cidr
    from_port = var.ssh_port
    to_port = var.ssh_port
  }

  ingress {
    protocol = "tcp"
    rule_no = "102"
    action = "allow"
    cidr_block = var.all_cidr
    from_port = var.jenkins_port
    to_port = var.jenkins_port
  }

  ingress {
    protocol = "tcp"
    rule_no = "103"
    action = "allow"
    cidr_block = var.all_cidr
    from_port = var.sonarqube_port
    to_port = var.sonarqube_port
  }

  ingress {
    protocol = "tcp"
    rule_no = "104"
    action = "allow"
    cidr_block = var.all_cidr
    from_port = var.grafana_port
    to_port = var.grafana_port
  }

  tags = {
    Name = "Main ACL"
  }

}

/*
Amazon Elastic Container Registry (Amazon ECR) is a fully managed Docker container registry service provided by AWS that simplifies the process of storing, managing, and deploying container images. 
ECR integrates seamlessly with Amazon Elastic Container Service (ECS), Amazon Elastic Kubernetes Service (EKS), and other AWS services, facilitating a streamlined workflow for containerized applications. 
Users can push container images to ECR, where they are securely stored and can be easily retrieved for deployment. With features like image versioning, lifecycle policies, and encryption, 
ECR helps ensure that container images are efficiently managed, secure, and readily available for deployment, enabling scalable and reliable containerized application development.
*/

# Create the ECR repository
resource "aws_ecr_repository" "ecr_repo" {
  name = "docker_repository"

  image_scanning_configuration {
    scan_on_push = true
  }
}
