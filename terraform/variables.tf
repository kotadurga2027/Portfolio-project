variable "ami_id" {
  description = "AMI ID to use for EC2 instance"
  type        = string
  default     = "ami-0220d79f3f480ecf5"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_path" {
  description = "Path to public SSH key for EC2"
  type        = string
  default     = "/var/lib/jenkins/.ssh/portfolio-key.pub"
}

variable "vpc_id" {
  description = "VPC ID where instance will be deployed"
  type        = string
  default     = "vpc-05813f60c10a64567"
}

variable "subnet_id" {
  description = "Subnet ID within the VPC"
  type        = string
  default     = "subnet-075ed3c763874ecda"
}

variable "sg_id" {
  description = "Security Group ID to attach"
  type        = string
  default     = "sg-06b449af837b8b674"
}

