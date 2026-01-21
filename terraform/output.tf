output "instance_ip" {
  value = aws_instance.portfolio.public_ip
}

output "instance_id" {
  value = aws_instance.portfolio.id
}