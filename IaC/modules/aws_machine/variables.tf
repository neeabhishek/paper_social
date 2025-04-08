variable "access_key" {
  type    = string
  default = "AKIA2ZDCK3WINBCZLF5Z"
}
variable "secret_key" {
  type    = string
  default = "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"
}
variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "filename" {
  type    = string
  default = "ec2.pem"
}
variable "ami" {
  type    = string
  default = "ami-0e35ddab05955cf57" #Ubuntu amazon machine image
}
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "cidr_blocks" {
  type    = string
  default = "0.0.0.0/0"
}
variable "environment" {
  type    = string
  default = "AWS_ENV"
}
variable "user" {
  type    = string
  default = "ubuntu" #Default user for the AMI used
}
variable "notification_email" {
  type    = string
  default = "neeabhishek@gmail.com"
}
