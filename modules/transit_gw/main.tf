module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"

  name        = "${var.name}-${var.environment}-transitgw"
  description = "My TGW shared with several other AWS accounts"

  enable_auto_accept_shared_attachments = true

  vpc_attachments = {
    vpc = {
      vpc_id       = var.vpc_id
      subnet_ids   = var.private_subnets
      dns_support  = true
      ipv6_support = false

      tgw_routes = [
        {
          destination_cidr_block = var.transitgw_dest_cidr_block
        }
      ]
    }
  }

  ram_allow_external_principals = true
  ram_principals = [307990089504]

  tags = {
    Purpose = "tgw-complete-example"
  }
}