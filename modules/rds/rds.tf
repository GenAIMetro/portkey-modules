locals {
  name   = "${var.name}-${var.environment}-mysql"
  region = var.region

  vpc_cidr = "10.0.0.0/16"
  azs      = var.availability_zones

  tags = {
    Name       = local.name
  }

  engine                = "mysql"
  engine_version        = "8.0"
  family                = "mysql8.0" # DB parameter group
  major_engine_version  = "8.0"      # DB option group
  instance_class        = var.rds_instance_size
  allocated_storage     = 20
  max_allocated_storage = 100
  port                  = 3306
}



module "master" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-master"

  engine               = local.engine
  engine_version       = local.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = local.instance_class
  
  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  manage_master_user_password = false
  port     = local.port

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]

  # Backups are required in order to create a replica
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = local.tags
}

################################################################################
# Replica DB
################################################################################

module "replica" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-replica"

  # Source database. For cross-region use db_instance_arn
  replicate_source_db = module.master.db_instance_identifier

  engine               = local.engine
  engine_version       = local.engine_version
  family               = local.family
  major_engine_version = local.major_engine_version
  instance_class       = local.instance_class

  allocated_storage     = local.allocated_storage
  max_allocated_storage = local.max_allocated_storage

  port = local.port

  password = var.db_password
  # Not supported with replicas
  manage_master_user_password = false

  multi_az               = false
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Tue:00:00-Tue:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = local.tags
}


module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Replica MySQL example security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = var.vpc_cidr
    },
  ]

  tags = local.tags
}

resource "aws_db_subnet_group" "rds_subnet_group" {

  // The name and description of the db subnet group
  name        = "${var.name}-${var.environment}_rds_subnet_group"
  description = "DB subnet group for rds"
  subnet_ids  = var.private_subnet_ids
  tags   = local.tags
}