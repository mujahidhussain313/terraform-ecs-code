output "as_arn" {
  value = aws_autoscaling_group.ecs_asg.arn
}

output "as_id" {
  value = aws_autoscaling_group.ecs_asg.id
}