output "iam-instance-profile-arn" {
  value = aws_iam_instance_profile.ecs_node.arn
}

output "task_def_role" {
  value = aws_iam_role.ecs_task_role.arn
}


output "task_defi_exec_role" {
  value = aws_iam_role.ecs_exec_role.arn
}