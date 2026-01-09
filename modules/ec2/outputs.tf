output "instance_id" { value = aws_instance.this.id }
output "public_ip"   { value = aws_instance.this.public_ip }
output "public_dns"  { value = aws_instance.this.public_dns }
output "private_ip"  { value = aws_instance.this.private_ip }

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "SG ID used by EC2 (use this to allow DB access)"
}

output "private_key_path" {
  value       = "${path.root}/${var.private_key_filename}"
  description = "Local path where the .pem was saved"
}
