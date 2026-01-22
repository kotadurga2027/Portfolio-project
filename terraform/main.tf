resource "aws_instance" "portfolio" {
  ami           = "ami-0220d79f3f480ecf5"
  instance_type = "t3.medium"

  tags = {
    Name = "Portfolio-Project"
  }
}
