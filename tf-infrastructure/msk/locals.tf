locals {
  cluster_name             = "msk-demo"
  kafka_version            = "2.8.1"
  region                   = "eu-west-1"
  msk_ami                  = "ami-0ed752ea0f62749af"
  msk_broker_instance_type = "kafka.t3.small"

  ec2_name          = "kafka-client-ec2"
  ec2_instance_type = "t3.small"
}
