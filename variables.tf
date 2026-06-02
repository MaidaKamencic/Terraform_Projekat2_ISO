variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  default     = "recipes_db"
}

variable "db_username" {
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  type        = string
  default     = "postgres123!"
  sensitive   = true
}

variable "s3_bucket_name" {
  type        = string
  default     = "recipes-app-static-assets"
}

variable "logo_file_path" {
  type        = string
  default     = "./assets/logo1.png"
}
