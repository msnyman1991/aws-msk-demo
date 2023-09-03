resource "aws_kms_key" "kafka_kms" {
  description             = "kms key for kafka client secrets"
  deletion_window_in_days = 10
  policy                  = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        },
        "Resource": "*",
        "Action": [
          "kms:CancelKeyDeletion",
          "kms:Create*",
          "kms:Delete*",
          "kms:Describe*",
          "kms:Disable*",
          "kms:Enable*",
          "kms:Get*",
          "kms:ImportKeyMaterial",
          "kms:List*",
          "kms:Put*",
          "kms:Revoke*",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:Update*",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyPair",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
          "kms:Sign",
          "kms:Verify"
        ]
      }]
    }
      EOF
}

resource "random_password" "kafka_admin_user" {
  length           = 16
  special          = true
  override_special = "_%@"
}

module "secret" {
  source = "../../modules/secrets"

  recovery_window_in_days = "0"
  kms_key_id              = aws_kms_key.kafka_client_secrets_key.id
  secrets = {
    "AmazonMSK_kafka_admin_user" = {
      description   = "Contains password for kafka-admin-user user on kafka client ec2 instance"
      secret_string = "{\"username\": \"admin\",\"password\": \"${random_password.kafka_admin_user.result}\"}"
    }
  }
}
