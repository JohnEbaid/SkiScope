variable "region" {
  type    = string
  default = "us-east-1"
}

# App Runner can't be created until an image exists in ECR, so deploy in two phases:
# apply with false -> push image -> apply with -var deploy_app=true
variable "deploy_app" {
  type    = bool
  default = false
}

variable "image_tag" {
  type    = string
  default = "latest"
}
