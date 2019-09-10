#variable "DBHOST"       {}
variable "DBUSER"       {}
variable "DBPASSWORD"   {}
variable "DATABASE"     {}



resource "aws_db_instance" "db" {
  identifier = "anewserver"     #This should be passed in as a variabl

  engine                              = "mysql"
  engine_version                      = "5.7"
  instance_class                      = "db.t2.micro"
  name                                = "${var.DATABASE}"
  username                            = "${var.DBUSER}"
  password                            = "${var.DBPASSWORD}"
  storage_type                        = "gp2"
  allocated_storage                   = 20
  parameter_group_name                = "default.mysql5.7"
  skip_final_snapshot                 = true   #We wouldnt want this on production, but for TF Testing it's fine

  #vpc_security_group_ids = [] #set later 
  iam_database_authentication_enabled = false #set this to true and create roles for ECS/tasks later
}



output "DBUSER" {
  description = "The Database User"
  value = "${aws_db_instance.db.username}"
}


output "DBPASSWORD" {
  description = "The Database User Password"
  value = "${aws_db_instance.db.password}"

}

output "DBHOST" {
  description = "The Database RDS Host Instace"
  value = "${aws_db_instance.db.address}"
}


output "DATABASE" {
  description = "The Database to use on the host"
  value = "${aws_db_instance.db.name}"
}