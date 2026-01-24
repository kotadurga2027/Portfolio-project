# EC2 instance
resource "aws_instance" "portfolio" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.portfolio_key.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = true

  tags = {
    Name = "Portfolio-Project"
  }
}








# resource "aws_instance" "portfolio" {
#   ami           = "ami-0220d79f3f480ecf5"
#   instance_type = "t3.medium"

#   tags = {
#     Name = "Portfolio-Project"
#   }
# }
