variable "cluster_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "owner" {
  type = string
}

variable "eks_public_access_cidrs" {
  type = list(string)
}

variable "desired_size" {
  type = number
}
variable "max_size" {
  type = number
}
variable "min_size" {
  type = number
}
variable "instance_types" {
  type = list(string)
}
variable "capacity_type" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}