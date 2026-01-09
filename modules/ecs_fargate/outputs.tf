output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_name" { value = aws_ecs_service.this.name }
output "tasks_sg_id" { value = aws_security_group.tasks.id }
output "target_group_arn" { value = aws_lb_target_group.this.arn }
output "log_group_name" { value = aws_cloudwatch_log_group.this.name }

