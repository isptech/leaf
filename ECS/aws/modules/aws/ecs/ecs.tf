variable "vpc_id"                        { }
variable "key_name"                      { }
variable "private_subnet_id"             { }
variable "public_subnet_id"              { }
variable "ami"                           { }

variable "sg"     {}

# variables from RDS

variable "DBHOST"       {}
variable "DBUSER"       {}
variable "DBPASSWORD"   {}
variable "DATABASE"     {}



resource "aws_ecs_cluster" "cluster" {
  name = "jg-cluster"
}


#. Create some policies we will need 

resource "aws_iam_role" "ecs-service-role" {
    name                = "ecs-service-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.ecs-service-policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
    role                = "${aws_iam_role.ecs-service-role.name}"
    policy_arn          = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
    statement {
        actions         = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "ecs-instance-role" {
    name                = "ecs-instance-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}

data "aws_iam_policy_document" "ecs-instance-policy" {
    statement {
        actions         = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
    role       = "${aws_iam_role.ecs-instance-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
    name      = "ecs-instance-profile"
    path      = "/"
    role      = "${aws_iam_role.ecs-instance-role.id}"
}

# Done with policies 


# ECS Configurations 
resource "aws_launch_configuration" "asg_conf" {
  name                        = "${aws_ecs_cluster.cluster.name}-host"
  image_id                    = "${var.ami}"  
  instance_type               = "t2.micro"
  key_name                    = "newmbp"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs-instance-profile.id}"
  lifecycle {
    create_before_destroy     = false   #bad for production, but fine for testing
  }
  # user data is necessary to tell an instance's ECS docker container which ECS cluster to join 
  user_data                    = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.cluster.name} > /etc/ecs/ecs.config"
}


resource "aws_autoscaling_group" asg {
  name = "ecs_asg"
  vpc_zone_identifier       = ["${var.private_subnet_id}"]  #Only launching in one subnet for now
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  launch_configuration      = "${aws_launch_configuration.asg_conf.id}"
    
}





## ECS services definitions here

resource "aws_ecs_task_definition" "task" {
  family = "somecontainers"

  #When passing in the definition for the tasks, we have to use the variables we set above for  DB connection string 
  # we can't  pull from the module here, but we can use terraform extrapolation for some reason
  # ideally we wouldnt do this and instead would pull form sevret manager, as these are exposed in ENV settings on a host
 container_definitions = <<EOF
[
  {
    "name": "leafly",
    "image": "isptech/leafl:1",
    "cpu": 0,
    "memory": 128,
    "portmappings": [ 
       { 
        "hostPort": 5000,
        "protocol": "tcp",
        "containerPort": 5000
       }

    ],
    "environment": [
      {
        "name": "DBUSER",
        "value": "${var.DBUSER}"
      },
      {
        "name": "DBPASSWORD",
        "value": "${var.DBPASSWORD}"
      },
      {
        "name": "DBHOST",
        "value": "${var.DBHOST}"
      },
      {
        "name": "DATABASE",
        "value": "${var.DATABASE}"
      },
      {
        "name": "DBPORT",
        "value": "3306"
      }
  
    ]
    
  }
]
EOF

}



resource "aws_ecs_service" "leafly" {
  name            = "leaf-app"
  cluster         = "${aws_ecs_cluster.cluster.name}"
  task_definition = aws_ecs_task_definition.task.arn

  desired_count   = 1

  load_balancer {
     target_group_arn = "${aws_alb_target_group.asg_tg.id}"
     container_name   = "leafly" #This is the container definition from the task def, not the service
     container_port   = "5000"
  }
}



# need a load balancer

resource "aws_alb" "alb" {
  name                       = "ECS-ASG"
  internal                   = false
  subnets                    = ["${var.private_subnet_id}", "subnet-6d718f35"  ]  #subnet-268a797e"
  security_groups            = [ "${var.sg}"  ]
  idle_timeout               = 60
  enable_deletion_protection = false

}

resource "aws_alb_target_group" "asg_tg" {
  name       = "${aws_alb.alb.name}"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = "${var.vpc_id}"

}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn  = "${aws_alb.alb.arn}"
  port               = "80"
  protocol           = "HTTP"
  default_action {
    target_group_arn = "${aws_alb_target_group.asg_tg.arn}"
    type             = "forward"
  }
}
