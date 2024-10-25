variable "region" {
  description = "The AWS region to deploy the infrastructure"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  default     = "10.0.4.0/24"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "key_name" {
  description = "The key pair name to access EC2 instances"
  default     = "tf_keypair"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  default     = "ami-02f64c390601e5f36"
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling group"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling group"
  default     = 5
}

variable "desired_capacity" {
  description = "Desired capacity of instances in the Auto Scaling group"
  default     = 3
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  default     = "t2.micro"
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host"
  default     = "ami-02f64c390601e5f36"
}

