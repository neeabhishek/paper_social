variable "access_key" {
  type    = string
  default = "" #Pass your IAM user access key
}
variable "secret_key" {
  type    = string
  default = "" #Pass your IAM user secret key
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
  default = "" #Pass your email address for alert notification.
}
