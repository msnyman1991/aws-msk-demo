locals {
  user_data = <<-EOT
    #!/bin/bash

    sudo yum install java-1.8.0 -y
    mkdir kafka
    cd kafka
    wget "https://archive.apache.org/dist/kafka/2.8.1/kafka_2.12-2.8.1.tgz"
    tar -xzf kafka_2.12-2.8.1.tgz
  
    touch users_jaas.conf

    echo 'KafkaClient {
      org.apache.kafka.common.security.scram.ScramLoginModule required
      username="admin"
      password="${random_password.kafka_admin_user.result}";
    };' >> users_jaas.conf
    
    echo 'security.protocol=SASL_SSL
          sasl.mechanism=SCRAM-SHA-512
          ssl.truststore.location=kafka.client.truststore.jks' > client_sasl.properties

    echo 'export KAFKA_OPTS=-Djava.security.auth.login.config=users_jaas.conf' >> ~/.bashrc

    cp /usr/lib/jvm/jre/lib/security/cacerts kafka.client.truststore.jks
  
  EOT
}

data "aws_iam_policy_document" "msk_client_ec2_policy" {
  statement {
    sid = "EC2SSMPermission"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:*",
      "ssm:UpdateInstanceStatus",
      "ssm:UpdateInstanceInformation",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateAssociationStatus",
      "ssm:StartSession",
      "ssm:PutInventory",
      "ssm:ListInstanceAssociations",
      "ssm:ListAssociations",
      "ssm:GetParameter",
      "ssm:GetDocument",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:DescribeInstanceAssociations",
      "ssm:DeleteAssociation",
      "ssm:CreateAssociation"
    ]
    resources = [
      "*"
    ]
  }
}

module "msk_client_ec2_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=v5.28.0"

  name        = "${local.ec2_name}-role-policy"
  path        = "/"
  description = "Policy for kafka client ec2-instance"

  policy = data.aws_iam_policy_document.msk_client_ec2_policy.json
}

module "msk_client_ec2_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git//?ref=v5.1.0"

  name        = "${local.ec2_name}-sg"
  description = "Security group for kafka client ec2"
  vpc_id      = module.msk_vpc.vpc_id

  ingress_cidr_blocks = [module.msk_vpc.vpc_cidr_block]
  ingress_rules       = ["all-tcp"]
  egress_rules        = ["all-all"]
}

module "msk_client_ec2" {
  source                 = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git//?ref=v5.2.1"
  name                   = local.ec2_name
  ami                    = local.msk_ami
  instance_type          = local.ec2_instance_type
  subnet_id              = module.msk_vpc.private_subnets[0]
  vpc_security_group_ids = [module.msk_client_ec2_security_group.security_group_id]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for Kafka client EC2 instance"
  iam_role_policies = {
    EC2InstanceAccess = module.msk_client_ec2_iam_policy.arn,
    EC2SSMAccess      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  user_data_base64 = base64encode(local.user_data)
}

module "metric_alarm" {
  source              = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/metric-alarm?ref=v4.3.0"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  threshold           = "0.02"
  period              = "3600"
  alarm_description   = "Stop instance when CPU is low for an hour"
  alarm_name          = "LowCPUAlarm"
  alarm_actions       = ["arn:aws:automate:${local.region}:ec2:stop"]

  dimensions = {
    InstanceId = module.msk_client_ec2.id
  }
  statistic = "Average"
}

