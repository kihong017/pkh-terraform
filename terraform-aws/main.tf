# --- root/main.tf ---

module "networking" {
  source           = "./networking"
  vpc_cidr         = local.vpc_cidr
  access_ip        = var.access_ip
  security_group   = local.security_group
  public_sn_count  = 2
  private_sn_count = 3
  max_subnets      = 20
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  db_subnet_group  = true
}

module "database" {
  source                 = "./database"
  db_storage             = 10 # gibibyte
  db_engine_version      = "5.7.22"
  db_instance_class      = "db.t2.micro"
  dbname                 = var.dbname
  dbuser                 = var.dbuser
  dbpassword             = var.dbpassword
  db_identifier          = "pkh-db"
  skip_db_snapshot       = true # in prod, probably set to false
  db_subnet_group_name   = module.networking.db_subnet_group_name[0]
  vpc_security_group_ids = module.networking.db_security_group
}

module "loadbalancing" {
  source                = "./loadbalancing"
  public_sg             = module.networking.public_sg
  public_subnets        = module.networking.public_subnets
  tg_port               = 80
  tg_protocol           = "HTTP"
  vpc_id                = module.networking.vpc_id
  lb_healthy_trashold   = 2
  lb_unhealthy_trashold = 2
  lb_timeout            = 3
  lb_interval           = 30
  listener_port         = 80
  listener_protocol     = "HTTP"
}

module "compute" {
  source              = "./compute"
  instance_count      = 2
  instance_type       = "t3.micro"
  public_sg           = module.networking.public_sg
  public_subnets      = module.networking.public_subnets
  vol_size            = 10
  key_name            = "pkhkey"
  public_key_path     = "/home/ubuntu/.ssh/keypkh.pub"
  user_data_path      = "${path.root}/userdata.tpl"
  dbname              = var.dbname
  dbuser              = var.dbuser
  dbpassword          = var.dbpassword
  db_endpoint         = module.database.db_endpoint
  lb_target_group_arn = module.loadbalancing.lb_target_group_arn
  tg_port             = 8000
}