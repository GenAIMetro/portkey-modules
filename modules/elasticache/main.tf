module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  cluster_id               = "${var.name}-${var.environment}-elasticache"
  create_cluster           = true
  create_replication_group = false

  engine_version = "7.1"
  node_type      = var.elasticache_node_type

  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true

  # Security group
  vpc_id = var.vpc_id
  security_group_rules = {
    ingress_vpc = {
      # Default type is `ingress`
      # Default port is based on the default engine port
      description = "VPC traffic"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  # Subnet Group
  subnet_ids = var.private_subnets

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "latency-tracking"
      value = "yes"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}