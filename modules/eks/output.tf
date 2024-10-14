output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
# output "cluster_ca_certificate" {
#   value = aws_eks_cluster.eks.certificate_authority[0].data
# }
# output "kubeconfig" {
#   sensitive = true
#   value = local.kubeconfig
# }