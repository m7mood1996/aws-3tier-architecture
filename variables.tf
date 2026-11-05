variable "aws_region" {
  type        = string
  description = "The target AWS deployment region"
  default     = "eu-north-1"
}

variable "db_username" {
  type        = string
  description = "The master username for the PostgreSQL database cluster"
  default     = "db_admin_user"
}

variable "db_password" {
  type        = string
  description = "The master password for the database. Must be at least 8 characters."
  sensitive   = true # Prevents Terraform from printing the password to your terminal screen
}