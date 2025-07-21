variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "strapi-demo"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "db_username" {
  default = "strapiuser"
}

variable "db_password" {
  default   = "StrapiDemo123!"
  sensitive = true
}

variable "db_name" {
  default = "strapidb"
}