module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "${var.name}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  single_nat_gateway  = var.enable_single_nat_gw
  # default_security_group_name = "${var.name}-${var.environment}"
  enable_nat_gateway = var.enable_nat_gw
  enable_vpn_gateway = var.enable_nat_gw

  tags = merge(local.default_tags, { "kubernetes.io/cluster/${var.name}-${var.environment}-cluster" = "shared" })
  public_subnet_tags = merge(local.default_tags, { "kubernetes.io/cluster/${var.name}-${var.environment}-cluster" = "shared","kubernetes.io/role/elb" = 1 })
  private_subnet_tags = merge(local.default_tags, { "kubernetes.io/cluster/${var.name}-${var.environment}-cluster" = "shared","kubernetes.io/role/internal-elb" = 1 })
}