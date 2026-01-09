bucket_name            = "flightbooking-dev-frontend-s1"
backend_image          = "123456789012.dkr.ecr.us-east-1.amazonaws.com/flight-booking-backend:latest"
backend_container_port = 8080
health_check_path      = "/health"

db_name     = "flightbooking"
db_username = "flightadmin"
db_password = "xxxxxx"
