variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "environment" {
  type = string
}
variable "availability_zones" {
  type = list(string)
}
variable "vpc_cidr" {
  type = string
}
variable "addon_tags" {
  type = map(string)
}
variable "elasticache_node_type" {
  type = string
}
variable "private_subnets" {
  type = any
}
variable "vpc_id" {
  
}