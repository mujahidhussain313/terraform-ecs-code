

output "alb_hostname" {
  value = aws_alb.alb.dns_name
}

output "alb_tg_arn" {
  value = aws_alb_target_group.myapp-tg.arn
}