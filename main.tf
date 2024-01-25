module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs                           
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "alb" {
  source = "./modules/alb"
  subnets_id = module.vpc.subnets_id
  vpc_id     = module.vpc.vpc_id
  sg_id    = module.sg.alb_sg_id
}

module "sg" {
  source = "./modules/security_group"
  vpc_id     = module.vpc.vpc_id
}

module "role" {
  source = "./modules/iam_role"
}


module "auto_scalling" {
  source = "./modules/auto_scalling"
  subnet_id = module.vpc.subnets_id
  sg_id   = module.sg.alb_sg_id
  iam-instance-profile-arn =  module.role.iam-instance-profile-arn
  ecs_cluster_name = var.ecs_cluster_name

}


module "ecs" {
  source = "./modules/ecs"
  as_arn =  module.auto_scalling.as_arn
  subnet_id =  module.vpc.subnets_id
  #sg_id   =  module.sg.alb_sg_id
  ecs_task-sg =  module.sg.ecs_task-sg
  alb_tg_arn =  module.alb.alb_tg_arn
  as_id =   module.auto_scalling.as_id
  ecs_cluster_name = var.ecs_cluster_name
  task_def_role = module.role.task_def_role
  task_defi_exec_role =  module.role.task_defi_exec_role
}