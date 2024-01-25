output "alb_sg_id" {
  value = aws_security_group.alb-sg.id
}

output "nodesg-id" {
    value = aws_security_group.ecs_node_sg.id
  
}

output "ecs_task-sg" {
    value = aws_security_group.ecs_task_sg.id
  
}