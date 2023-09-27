# --- compute/outputs.tf ---

output "instance" {
    value = aws_instance.pkh_node[*]
    sensitive = true
}

output "instance_port" {
    value = aws_lb_target_group_attachment.pkh_tg_attach[0].port
}