output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "app_endpoint" {
  value = try(aws_ecs_express_gateway_service.app[0].ingress_paths[0].endpoint, "not deployed yet (deploy_app = false)")
}
