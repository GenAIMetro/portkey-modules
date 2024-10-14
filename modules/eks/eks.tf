module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = "${var.name}-${var.environment}-cluster"
  cluster_version                = var.k8s_version
  cluster_endpoint_public_access = true
  create_cloudwatch_log_group    = false
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.control_plane_subnets

  #EKS Managed Node Group(s)
  # eks_managed_node_group_defaults = {
  #   instance_types       = ["t2.medium", "t2.large"]
  #   bootstrap_extra_args = "--container-runtime containerd --kubelet-extra-args '--max-pods=110'"
  #   disk_size            = var.node_disk_size
  # }

  eks_managed_node_groups = { for node_name, node_specs in var.node_group_specs :
    node_name => {
      name           = "${var.name}-${var.environment}-${node_name}"
      min_size       = node_specs.min_size
      max_size       = node_specs.max_size
      desired_size   = node_specs.desire_size
      instance_types = ["${node_specs.instance_type}"]
      capacity_type  = node_specs.capacity_type
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = node_specs.disk_size
            volume_type           = "gp3"
            iops                  = 16000
            throughput            = 1000
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }
  # create_aws_auth_configmap = false
  manage_aws_auth_configmap = true


  aws_auth_users = concat(
    [for users in data.aws_iam_group.admin_group.users : {
      userarn  = "${users.arn}"
      username = "${users.user_name}"
      groups   = ["system:masters"]
      }
    ]
  )



  tags = merge(local.default_tags)
}

data "aws_iam_group" "admin_group" {
  group_name = var.iam_admin_group
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks]
  name       = module.eks.cluster_name
}

#EFS FIle System

module "attach_efs_csi_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "efs-csi-${var.name}-${var.environment}"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

resource "aws_security_group" "allow_nfs" {
  name        = "allow nfs for efs"
  description = "Allow NFS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "NFS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

resource "kubernetes_storage_class" "efs_sc" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  parameters = {
    type             = "pd-standard",
    provisioningMode = "efs-ap",
    fileSystemId     = aws_efs_file_system.stw_node_efs.id,
    directoryPerms : "700"

  }
}
resource "aws_efs_file_system" "stw_node_efs" {
  creation_token = "efs-${var.name}-${var.environment}-cluster-token"
  tags = merge(local.default_tags,
    { Name = "efs-${var.name}-${var.environment}-cluster" }
  )

}

resource "aws_efs_mount_target" "stw_node_efs_mt" {
  count           = length(var.private_subnets[*])
  file_system_id  = aws_efs_file_system.stw_node_efs.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.allow_nfs.id]
}

resource "helm_release" "aws_efs_csi_driver" {
  chart      = "aws-efs-csi-driver"
  name       = "aws-efs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/eks/aws-efs-csi-driver"
  }

  set {
    name  = "controller.serviceAccount.create"
    value = true
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.attach_efs_csi_role.iam_role_arn
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "efs-csi-controller-sa"
  }
}