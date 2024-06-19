resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}



resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

# Define CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/srb_app"
  retention_in_days = 14
}

# Define ECS task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family             = "srb-ecs-task"
  network_mode       = "awsvpc"
  task_role_arn      = var.task_def_role
  execution_role_arn = var.task_defi_exec_role
  cpu                = 512
  memory             = 1024

  requires_compatibilities = ["FARGATE"]

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
        }
      ],
      environment = [
        { name = "EXAMPLE", value = "example" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = "ap-south-1"
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-stream-prefix" = "srb_app"
        }
      }
    }
  ])
}

# Define ECS service for Fargate launch type
resource "aws_ecs_service" "ecs_service" {
  name            = "srb-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.name
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_id
    security_groups = [var.ecs_task-sg]
    assign_public_ip = true
  }

  force_new_deployment = true

  triggers = {
    redeployment = timestamp()
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = "srb_app"
    container_port   = 80
  }

  # ordered_placement_strategy {
  #   type  = "spread"
  #   field = "attribute:ecs.availability-zone"
  # }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [var.alb_tg_arn]
}
