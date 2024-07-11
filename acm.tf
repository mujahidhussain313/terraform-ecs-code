provider "aws" {
  region = var.region
}

resource "aws_acm_certificate" "acm_certificate" {
  domain_name       = "acmalb.mujahidhussain.store"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "example" {
  name = "mujahidhussain.store"
}

resource "aws_route53_record" "validation_route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = aws_route53_zone.example.zone_id
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_route53_record : record.fqdn]
}

resource "aws_alb_listener" "frontend443_alb_listener" {
  load_balancer_arn = var.alb_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.acm_certificate.arn

  default_action {
    target_group_arn = var.alb_tg_arn
    type             = "forward"
  }
}



variable "alb_arn" {
  type = string
  description = "ARN of your LoadBalance that you want to attach with WAF.."
}
variable "alb_tg_arn" {
  type = string
  description = "alb tg arn"
}
variable "region" {
  type = string
}
