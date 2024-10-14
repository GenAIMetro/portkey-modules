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
variable "vpc_id" {
  type = any
}
variable "public_subnets" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}
variable "addon_tags" {
  type = map(string)
}
variable "k8s_version" {
  type = string
}
variable "node_group_specs" {
  type = any
}
variable "iam_admin_group" {
  type = string
}
variable "control_plane_subnets" {
  type = any
}