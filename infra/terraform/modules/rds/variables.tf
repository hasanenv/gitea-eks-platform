variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_username" {
  type = string
}

variable "owner" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "eks_node_security_group_id" {
  type = string
}