# --- networking/main.tf ---

data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "pkh_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "pkh_vpc-${random_integer.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "pkh_public_subnet" {
  count      = var.public_sn_count
  vpc_id     = aws_vpc.pkh_vpc.id
  cidr_block = var.public_cidrs[count.index]
  # This is usually default to false for private
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "pkh_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "pkh_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.pkh_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.pkh_public_rt.id
}

resource "aws_subnet" "pkh_private_subnet" {
  count      = var.private_sn_count
  vpc_id     = aws_vpc.pkh_vpc.id
  cidr_block = var.private_cidrs[count.index]
  # This is usually default to false for private
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "pkh_private_${count.index + 1}"
  }
}

resource "aws_internet_gateway" "pkh_internet_gateway" {
  vpc_id = aws_vpc.pkh_vpc.id

  tags = {
    Name = "pkh_igw"
  }
}

resource "aws_route_table" "pkh_public_rt" {
  vpc_id = aws_vpc.pkh_vpc.id

  tags = {
    Name = "pkh_public"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.pkh_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.pkh_internet_gateway.id
}

# Using the default route table created by VPC
resource "aws_default_route_table" "pkh_private_rt" {
  default_route_table_id = aws_vpc.pkh_vpc.default_route_table_id

  tags = {
    Name = "pkh_private"
  }
}

resource "aws_security_group" "pkh_sg" {
  for_each = var.security_group
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.pkh_vpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks 
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means All protocol
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "pkh_rds_subnetgroup" {
  count = var.db_subnet_group ? 1: 0
  name = "pkh_rds_subnetgroup"
  subnet_ids = aws_subnet.pkh_private_subnet.*.id
  tags = {
    Name = "pkh_rds_sngc"
  }
}