variable "subnet_id" {
  description = "subnet id for auto scalling"
}

variable "sg_id" {
  description = "svpc id for alb"
}

variable "iam-instance-profile-arn" {
  type = string
  default = ""
}

variable "ecs_cluster_name" {
  type = string
  default = "mujahid_ecs_clstr"
}