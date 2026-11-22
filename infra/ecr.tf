resource "aws_ecr_repository" "app" {
  name                 = "skiscope"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # lets `terraform destroy` remove the repo even if it holds images

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Keep storage costs near zero: only the 5 most recent images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
