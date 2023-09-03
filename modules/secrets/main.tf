resource "aws_secretsmanager_secret" "this" {
  for_each                = { for k, v in var.secrets : k => v }
  name                    = each.key
  kms_key_id              = var.kms_key_id
  description             = each.value.description
  recovery_window_in_days = var.recovery_window_in_days
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = { for k, v in var.secrets : k => v }
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string

  lifecycle {
    ignore_changes  = [secret_string]
    prevent_destroy = true
  }
}

output "secret_arn" {
  value = {
    for secret_name, secret in var.secrets : secret_name => aws_secretsmanager_secret_version.this[secret_name].arn
  }
}

output "secret_id" {
  value = {
    for secret_name, secret in var.secrets : secret_name => aws_secretsmanager_secret_version.this[secret_name].id
  }
}