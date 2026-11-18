output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "lb_controller_role_arn" {
  value       = module.irsa_lb_controller.role_arn
  description = "Annotate the aws-load-balancer-controller service account with this."
}

output "irsa_demo_role_arn" {
  value       = module.irsa_demo.role_arn
  description = "Annotate the irsa-demo service account with this."
}
