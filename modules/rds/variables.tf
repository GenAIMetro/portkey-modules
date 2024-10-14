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
variable "rds_instance_size" {
  type = string
}
variable "rds_instance_names" {
  type = any
}
variable "db_name" {
  type = string
}
variable "db_user" {
  type = string
}
variable "db_password" {
  type = string
}
variable "vpc_id" {
  type = any
}
variable "private_subnet_ids" {
  type = any
}