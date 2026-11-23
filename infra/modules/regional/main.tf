terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.40.0"
    }
  }
}

module "vpc" {
  source = "./vpc"

  vpc_name              = var.name_prefix
  vpc_cidr              = "10.0.0.0/16"
  vpc_azs               = var.availability_zones
  vpc_private_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  vpc_public_subnets    = ["10.0.4.0/24", "10.0.5.0/24"]
  # No public NAT gateway: this template provisions only VPC + internet-facing
  # ELB (which has its own EIP) + IAM agency. There is no compute that needs
  # outbound NAT egress, so we keep cost and attack surface minimal.
  vpc_enable_nat_gateway = false
  single_nat_gateway     = (var.env == "prod" ? false : true)
  vpc_tags              = {
    Environment = var.env
    Name        = var.name_prefix
  }
}

# ---------------------------------------------------------------------------
# Internet-facing application load balancer (Huawei Cloud ELB, L7 flavor)
# ---------------------------------------------------------------------------

# L7 flavor must be looked up per region. We match by EXACT name
# (never data.xxx.ids[0]) so the chosen spec is predictable.
data "huaweicloud_elb_flavors" "l7" {
  type = "L7"
}

locals {
  l7_flavor_id = [for f in data.huaweicloud_elb_flavors.l7.flavors : f.id if f.name == var.elb_l7_flavor_name][0]
}

# Public EIP bound to the load balancer so it is reachable from the internet.
resource "huaweicloud_vpc_eip" "elb" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.name_prefix}-elb-bw"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_elb_loadbalancer" "ext_lb" {
  name                  = "${var.name_prefix}-elb"
  l7_flavor_id          = local.l7_flavor_id
  vpc_id                = module.vpc.vpc_id
  ipv4_subnet_id        = module.vpc.public_subnet_ipv4_ids[0] # IPv4 subnet id
  availability_zone     = toset([var.availability_zones[0]])
  ipv4_eip_id           = huaweicloud_vpc_eip.elb.id

  tags = {
    Environment = var.env
    Account     = var.account
  }
}

# Backend pool. The listener forwards traffic to this pool.
# Add members (huaweicloud_elb_member) when you have a real backend. Until
# then the pool is empty and the listener still deploys successfully.
resource "huaweicloud_elb_pool" "ext_lb" {
  name             = "${var.name_prefix}-pool"
  protocol         = "HTTP"
  lb_method        = "ROUND_ROBIN"
  loadbalancer_id  = huaweicloud_elb_loadbalancer.ext_lb.id
}

resource "huaweicloud_elb_listener" "ext_lb" {
  loadbalancer_id = huaweicloud_elb_loadbalancer.ext_lb.id
  protocol        = "HTTP"
  protocol_port   = 80

  # Huawei ELB has no fixed-response action; forward to the (currently empty)
  # backend pool. With no members the listener returns 404.
  default_pool_id = huaweicloud_elb_pool.ext_lb.id
}

# ---------------------------------------------------------------------------
# Security group
# NOTE: Huawei enhanced ELB does not consume traditional security groups; the
# listener above is open on :80 from anywhere, which matches the intent of
# "allow 0.0.0.0/0 :80". We keep the SG resource to attach to backends later.
# Egress-all is auto-added by Huawei,
# so no explicit egress rule is created here.
# ---------------------------------------------------------------------------
resource "huaweicloud_networking_secgroup" "external_facing_web_sg" {
  name        = "external-facing-web-sg"
  description = "Allow inbound HTTP from anywhere (matches the listener intent)"
}

resource "huaweicloud_networking_secgroup_rule" "web_ingress_80" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.external_facing_web_sg.id
}
