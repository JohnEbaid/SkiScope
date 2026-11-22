data "aws_vpc" "default" {
  default = true
}

# special = false keeps the password safe to embed in a URL without escaping
resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_security_group" "db" {
  name        = "skiscope-db"
  description = "Postgres for SkiScope"
  vpc_id      = data.aws_vpc.default.id

  # App Runner has no fixed egress IPs without a VPC connector (which needs a ~$33/mo NAT
  # gateway for outbound internet). Protection instead: forced SSL + 32-char random password.
  ingress {
    description = "Postgres from anywhere (SSL required, password auth)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "pg16" {
  name   = "skiscope-pg16"
  family = "postgres16"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "skiscope"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "skiscope"
  username = "skiscope"
  password = random_password.db.result

  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.pg16.name

  # Demo database: only the latest weather snapshot, easy to rebuild. Not production settings.
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}
