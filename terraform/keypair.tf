resource "aws_key_pair" "portfolio_key" {
  key_name   = "portfolio-key"
  public_key = file("/var/lib/jenkins/.ssh/portfolio-key.pub")
}


# keyfile