terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.40.0"
    }
  }
}

# Native Huawei Cloud VPC module.
# Implements: VPC + public/private subnets + internet gateway + optional NAT.
# No NAT gateway by default: the only public egress need (ELB) uses its own
# EIP, and there is no compute requiring outbound NAT.
# Set vpc_enable_nat_gateway=true to add one.

resource "huaweicloud_vpc" "this" {
  name = var.vpc_name
  cidr = var.vpc_cidr
  tags = var.vpc_tags
}

# VPC-level internet gateway (required for EIP SNAT/DNAT).
resource "huaweicloud_vpc_internet_gateway" "this" {
  vpc_id = huaweicloud_vpc.this.id
  # Create only after subnets exist to avoid an API race ("Subnet not exists").
  depends_on = [huaweicloud_vpc_subnet.public, huaweicloud_vpc_subnet.private]
}

resource "huaweicloud_vpc_subnet" "public" {
  count         = length(var.vpc_public_subnets)
  name          = "${var.vpc_name}-public-${count.index}"
  cidr          = var.vpc_public_subnets[count.index]
  gateway_ip    = cidrhost(var.vpc_public_subnets[count.index], 1)
  vpc_id        = huaweicloud_vpc.this.id
  availability_zone = element(var.vpc_azs, count.index)
  tags          = merge(var.vpc_tags, var.vpc_public_subnet_tags)
}

resource "huaweicloud_vpc_subnet" "private" {
  count         = length(var.vpc_private_subnets)
  name          = "${var.vpc_name}-private-${count.index}"
  cidr          = var.vpc_private_subnets[count.index]
  gateway_ip    = cidrhost(var.vpc_private_subnets[count.index], 1)
  vpc_id        = huaweicloud_vpc.this.id
  availability_zone = element(var.vpc_azs, count.index)
  tags          = merge(var.vpc_tags, var.vpc_private_subnet_tags)
}

# --- NAT gateway for private-subnet egress --------------------------------
locals {
  # single_nat_gateway=true  -> 1 NAT; otherwise 1 per AZ
  nat_count = var.vpc_enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.vpc_azs)) : 0
}

resource "huaweicloud_vpc_eip" "nat" {
  count = local.nat_count
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.vpc_name}-nat-bw"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_nat_gateway" "this" {
  count           = local.nat_count
  name            = "${var.vpc_name}-nat-${count.index}"
  spec            = var.nat_spec
  vpc_id          = huaweicloud_vpc.this.id
  subnet_id       = huaweicloud_vpc_subnet.public[count.index].id
}

resource "huaweicloud_nat_snat_rule" "private" {
  count           = var.vpc_enable_nat_gateway ? length(huaweicloud_vpc_subnet.private) : 0
  nat_gateway_id  = huaweicloud_nat_gateway.this[count.index % local.nat_count].id
  subnet_id       = huaweicloud_vpc_subnet.private[count.index].id
  floating_ip_id  = huaweicloud_vpc_eip.nat[count.index % local.nat_count].id
}

# Default route to NAT for private-subnet internet egress:
# append to the VPC default route table, do NOT create a second table.
data "huaweicloud_vpc_route_table" "default" {
  vpc_id = huaweicloud_vpc.this.id
}

resource "huaweicloud_vpc_route" "private_nat" {
  count           = local.nat_count
  vpc_id          = huaweicloud_vpc.this.id
  route_table_id  = data.huaweicloud_vpc_route_table.default.id
  destination     = "0.0.0.0/0"
  type            = "nat"
  nexthop         = huaweicloud_nat_gateway.this[count.index].id
}
