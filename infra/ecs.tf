# App Runner is closed to new AWS customers (April 2026); AWS recommends ECS Express Mode:
# Fargate containers behind an auto-created load balancer with HTTPS and autoscaling.

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/skiscope"
  retention_in_days = 7 # cheap: logs expire after a week
}

resource "aws_ecs_express_gateway_service" "app" {
  count        = var.deploy_app ? 1 : 0
  service_name = "skiscope"

  execution_role_arn      = aws_iam_role.ecs_execution.arn
  infrastructure_role_arn = aws_iam_role.ecs_infrastructure.arn

  cpu               = "256"
  memory            = "1024" # Streamlit + pandas + plotly is tight in 512 MB
  health_check_path = "/_stcore/health"

  # One task only: the dashboard doesn't need to scale, and each task costs money
  scaling_target = [{
    min_task_count            = 1
    max_task_count            = 1
    auto_scaling_metric       = "AVERAGE_CPU" # required field; irrelevant while max = min
    auto_scaling_target_value = 70
  }]

  primary_container {
    image          = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
    container_port = 8501

    # Injected as the DATABASE_URL env var, exactly what app.py already reads
    secret {
      name       = "DATABASE_URL"
      value_from = aws_secretsmanager_secret.database_url.arn
    }

    aws_logs_configuration = [{
      log_group         = aws_cloudwatch_log_group.app.name
      log_stream_prefix = "app"
    }]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy_attachment.ecs_infrastructure,
    aws_iam_role_policy.read_database_url,
  ]
}
