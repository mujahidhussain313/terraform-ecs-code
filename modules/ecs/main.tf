resource "aws_ecs_cluster" "ecs_cluster" {
 name = var.ecs_cluster_name
}
#......capacity provider........ 



resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "test1"

 auto_scaling_group_provider {
   auto_scaling_group_arn = var.as_arn
   managed_termination_protection = "DISABLED"

   managed_scaling {
     maximum_scaling_step_size = 2
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 100
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = var.ecs_cluster_name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}


# .........cloud watch logs....... 

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/myapp"
  retention_in_days = 14
}

# .............Task Definitation.........  


resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "myapp-ecs-task"
 network_mode       = "awsvpc"
 task_role_arn      =    var.task_def_role
 execution_role_arn =    var.task_defi_exec_role      
 cpu                = 1024
 memory             = 1024
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }
 container_definitions = jsonencode([
   {
     name      = "myapp"
     image     = "nginx:latest"
     cpu       = 512
     memory    = 512
     essential = true
     portMappings = [
       {
         containerPort = 80
         hostPort      = 80
         #protocol      = "tcp"
       }
     ],
     environment = [
      { name = "EXAMPLE", value = "example" }
    ]
     logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "us-east-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "myapp"
      }
    },
   }
 ])
}


#..........ECS Service .......... 

resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = aws_ecs_cluster.ecs_cluster.name
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 2

 network_configuration {
   subnets         =   var.subnet_id
   security_groups = [var.ecs_task-sg]
 }

 force_new_deployment = true
#  placement_constraints {
#    type = "distinctInstance"
#  }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   base              = 1
   weight            = 100
 }

 load_balancer {
   target_group_arn = var.alb_tg_arn
   container_name   = "myapp"
   container_port   = 80
 }
 ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  lifecycle {
    ignore_changes = [desired_count]
  }

 depends_on = [var.alb_tg_arn]
}























# data "template_file" "testapp" {
#   template = file("../alb/templates/image/image.json")

#   vars = {
#     app_image      = var.app_image
#     app_port       = var.app_port
#     fargate_cpu    = var.fargate_cpu
#     fargate_memory = var.fargate_memory
#     aws_region     = var.aws_region
#   }
# }

# resource "aws_ecs_task_definition" "test-def" {
#   family                   = "testapp-task"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = var.fargate_cpu
#   memory                   = var.fargate_memory
#   container_definitions    = data.template_file.testapp.rendered
# }

# resource "aws_ecs_service" "test-service" {
#   name            = "testapp-service"
#   cluster         = aws_ecs_cluster.test-cluster.id
#   task_definition = aws_ecs_task_definition.test-def.arn
#   desired_count   = var.app_count
#   launch_type     = "FARGATE"

#   network_configuration {
#     security_groups  = [aws_security_group.ecs_sg.id]
#     subnets          = aws_subnet.private.*.id
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_alb_target_group.myapp-tg.arn
#     container_name   = "testapp"
#     container_port   = var.app_port
#   }

#   depends_on = [aws_alb_listener.testapp, aws_iam_role_policy_attachment.ecs_task_execution_role]
# }
