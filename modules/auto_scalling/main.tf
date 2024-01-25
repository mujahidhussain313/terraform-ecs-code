##.............. auto scalling group ............. 

resource "aws_autoscaling_group" "ecs_asg" {
 name_prefix               = "myapp-ecs-asg"
 vpc_zone_identifier =  var.subnet_id
 desired_capacity    = 2
 max_size            = 5
 min_size            = 2
 health_check_type         = "EC2"
 protect_from_scale_in     = false

 launch_template {
   id      = aws_launch_template.ecs_lt.id
   version = "$Latest"
 }

 tag {
    key                 = "Name"
    value               = "myapp-ecs-asg"
    propagate_at_launch = true
  }

 tag {
   key                 = "AmazonECSManaged"
   value               = ""
   propagate_at_launch = true
 }
}


#...................... launch template.............. 

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}


resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      =  data.aws_ssm_parameter.ecs_node_ami.value                             #"ami-0c0b74d29acd0cd97"
 instance_type = "t2.medium"
 vpc_security_group_ids = [var.sg_id]
 key_name               = "mujahid-key"
 
 iam_instance_profile {
   arn = var.iam-instance-profile-arn
 }
 monitoring { enabled = true }


 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }


 user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config;
    EOF
  )
}

#................creating key-pair for ec2 .............

resource "aws_key_pair" "key_tf" {
  key_name = "mujahid-key"
  public_key = file("${path.module}/id_rsa.pub")
}



