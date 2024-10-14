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
variable "transitgw_dest_cidr_block" {
  type = any
}
variable "private_subnets" {
  type = any
}
variable "vpc_id" {
  type = any
}