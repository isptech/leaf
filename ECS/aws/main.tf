variable "vpc_id"                        { default = "vpc-14b92070" }
variable "key_name"                      { }
variable "private_subnet_id"             { default = "subnet-0e902578" } #subnet-022f21dee7cc7e742. #sandbox: subnet-8348dde7 
variable "public_subnet_id"              { }
variable "vpc_env_name"                  { }
variable "ami"                           { default = "ami-0e434a58221275ed4" }

variable "DBUSER"                        { }
variable "DBPASSWORD"                    { }
variable "DATABASE"                      { }



provider "aws" {
  region    = "us-west-2"
  profile   = "jg"
}

module "ecs" {
   source = "./modules/aws/ecs"
   vpc_id                               = "${var.vpc_id}"
   key_name                             = "${var.key_name}"
   private_subnet_id                    = "${var.private_subnet_id}"
   public_subnet_id                     = "${var.public_subnet_id}"
   ami                                  = "${var.ami}"
   sg                                   = "${aws_security_group.sg1.id}"
   DBHOST                               =  module.rds.DBHOST 
   DBUSER                               =  module.rds.DBUSER 
   DBPASSWORD                           =  module.rds.DBPASSWORD 
   DATABASE                             =  module.rds.DATABASE
}


module "rds" {
  source = "./modules/aws/rds"

   DBUSER            =  "${var.DBUSER}"  
   DBPASSWORD        =  "${var.DBPASSWORD}"  
   DATABASE          =  "${var.DATABASE}" 

}


resource "aws_security_group" "sg1" {
  vpc_id = "${var.vpc_id}"
  name = "new_sg"
 
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
 

 egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }


}



