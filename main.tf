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
/*
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet1.id
  tags = {
    Name = "NAT Gateway"
  }
}
*/
