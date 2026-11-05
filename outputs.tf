

output "alb_public_dns" {
  description = "The public DNS URL of your Application Load Balancer. Paste this into your browser!"
  value       = "http://${aws_lb.external_alb.dns_name}"
}