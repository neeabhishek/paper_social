provider "aws" {
  region     = var.region
}

module "aws_machine" {
    source = "./modules/aws_machine"
    ami = var.ami
    instance_type = var.instance_type
}
