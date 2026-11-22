resource "aws_secretsmanager_secret" "database_url" {
  name                    = "skiscope/database-url"
  recovery_window_in_days = 0 # delete immediately on destroy so the name can be reused
}

# App Runner injects this as the DATABASE_URL env var, exactly what app.py already reads
resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id
  secret_string = format(
    "postgresql+psycopg2://%s:%s@%s:5432/%s?sslmode=require",
    aws_db_instance.main.username,
    random_password.db.result,
    aws_db_instance.main.address,
    aws_db_instance.main.db_name,
  )
}
