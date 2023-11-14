

resource "aws_ecr_repository" "aws-ecr" {
  name         = "app-ecr-repository"
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "ecr-repo-policy" {
  repository = aws_ecr_repository.aws-ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 2 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 2
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "application_cluster"
}

resource "aws_ecs_service" "frontend" {
  name                               = "frontend-app"
  cluster                            = aws_ecs_cluster.app_cluster.id
  task_definition                    = aws_ecs_task_definition.frontend_task.arn
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 300
  launch_type                        = "EC2"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1


  force_new_deployment = true
  load_balancer {
    target_group_arn = aws_lb_target_group.tg[0].arn
    container_name   = "app" 
    container_port   = "80" # Application Port
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }

 policy
  lifecycle {
    ignore_changes = [task_definition, desired_count, load_balancer]
  }
}


resource "aws_ecs_task_definition" "frontend_task" {
  family = "frontend-task" 
  container_definitions = jsonencode([{


    name      = "app",
    image     = "${var.aws_account_id}.dkr.ecr.${var.aws_account_region}.amazonaws.com/app-ecr-repository:<revision_number>",
    essential = true,
    portMappings = [
      {
        "containerPort" : 80 # Application Port
      }
    ],




    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.region
      }
    }
  }])
  requires_compatibilities = ["EC2"] # Stating that we are using ECS Fargate # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 1800    # Specifying the memory our container requires
  cpu                      = 512     # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.app_task_role.arn

}
