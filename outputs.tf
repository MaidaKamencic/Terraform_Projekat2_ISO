output "alb_url" {
  description = "URL aplikacije"
  value       = "http://${aws_lb.main.dns_name}"
}

output "s3_bucket_name" {
  description = "Naziv S3 bucketa za staticki sadrzaj"
  value       = "recipes-app-static-assets"
}

output "ec2_instance_1_public_ip" {
  description = "Javna IP adresa EC2 instance 1"
  value       = aws_instance.app_1.public_ip
}

output "ec2_instance_2_public_ip" {
  description = "Javna IP adresa EC2 instance 2"
  value       = aws_instance.app_2.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}