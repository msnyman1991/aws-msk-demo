module "msk_broker_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git//?ref=v5.1.0"

  name         = "msk-brokers-sg"
  description  = "Security group for kafka msk cluster brokers"
  vpc_id       = module.msk_vpc.vpc_id
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 2181
      to_port     = 2181
      protocol    = "tcp"
      description = "Allow Zookeeper MSK"
      cidr_blocks = "${module.msk_vpc.vpc_cidr_block}"
    },
    {
      from_port   = 2182
      to_port     = 2182
      protocol    = "tcp"
      description = "Allow Zookeeper MSK TLS"
      cidr_blocks = "${module.msk_vpc.vpc_cidr_block}"
    },
    {
      from_port   = 9096
      to_port     = 9096
      protocol    = "tcp"
      description = "Allow SASL/SCRAM"
      cidr_blocks = "${module.msk_vpc.vpc_cidr_block}"
    }
  ]
}

module "msk_cluster" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-msk-kafka-cluster.git//?ref=v2.1.0"

  name                   = local.cluster_name
  kafka_version          = local.kafka_version
  number_of_broker_nodes = 3

  broker_node_client_subnets  = module.msk_vpc.private_subnets
  broker_node_instance_type   = local.msk_broker_instance_type
  broker_node_security_groups = [module.msk_broker_security_group.security_group_id]
  broker_node_storage_info = {
    ebs_storage_info = { volume_size = 100 }
  }

  encryption_in_transit_client_broker = "TLS"
  encryption_in_transit_in_cluster    = true

  cloudwatch_logs_enabled = true

  client_authentication = {
    sasl = { scram = true }
  }
  create_scram_secret_association = true
  scram_secret_association_secret_arn_list = [
    module.secret.secret_arn["AmazonMSK_kafka_admin_user"],
  ]

  create_schema_registry = true
}