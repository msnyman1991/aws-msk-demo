module "msk_vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//"

  name = local.vpc_name

  cidr            = ["10.10.0.0/16"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets  = ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_max_aggregation_interval    = 60
  create_flow_log_cloudwatch_iam_role  = true

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    Name = "${local.vpc_name}-private-subnet"
  }

  public_subnet_tags = {
    Name = "${local.vpc_name}-public-subnet"
  }

  private_route_table_tags = {
    Name = "${local.vpc_name}-private-rt"
  }

  public_route_table_tags = {
    Name = "${local.vpc_name}-public-rt"
  }

  tags = {
    Name = "${local.vpc_name}"
  }
}
