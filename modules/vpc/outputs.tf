output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public (web) subnet IDs"
}

output "app_subnet_ids" {
  value       = aws_subnet.app[*].id
  description = "Private application subnet IDs"
}

output "db_subnet_ids" {
  value       = aws_subnet.db[*].id
  description = "Private database subnet IDs"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "Internet Gateway ID"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.main[*].id
  description = "NAT Gateway IDs"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "app_route_table_ids" {
  value       = aws_route_table.app[*].id
  description = "App route table IDs"
}

output "db_route_table_ids" {
  value       = aws_route_table.db[*].id
  description = "DB route table IDs"
}
