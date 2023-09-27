# --- loadbalancing/outputs.tf ---

output "lb_target_group_arn" {
    value = aws_lb_target_group.pkh_tg.arn
}

output "lb_endpoint" {
    value = aws_lb.pkh_lb.dns_name
}

output "tg_port" {
    value = aws_lb_target_group.pkh_tg.port
}