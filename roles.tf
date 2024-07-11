resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole14"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"  # Adjust permissions as needed
  ]

  inline_policy {
    name = "AllowSSMParameterStoreAccess"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ssm:GetParameters",
            "ssm:GetParameter"
          ],
          Resource = [
            var.db_password_ssm_arn,
            var.db_username_ssm_arn,
            "arn:aws:ssm:*:*:parameter/myapp/*"
          ]
        }
      ]
    })
  }
}




####### task role   #########

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # Example policy, replace with necessary policies
}

resource "aws_iam_role_policy_attachment" "ecs_task_ecr_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_policy" "ecs_task_ssm_custom_policy" {
  name        = "AllowSSMParameterStoreAccess"
  description = "Custom policy for accessing SSM parameters"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [
          var.db_password_ssm_arn,
          var.db_username_ssm_arn,
          "arn:aws:ssm:*:*:parameter/myapp/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_custom_ssm_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_ssm_custom_policy.arn
}




output "task_defi_task_role" {
  value = aws_iam_role.ecs_task_role.arn
}


output "task_defi_execution_role" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

variable "db_password_ssm_arn" {
  type = string
}
variable "db_username_ssm_arn" {
  type = string
}
