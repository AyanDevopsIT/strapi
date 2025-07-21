output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}

output "strapi_url" {
  value = "http://${aws_instance.strapi.public_ip}:1337"
}

output "rds_endpoint" {
  value = aws_db_instance.strapi.address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.media.bucket
}