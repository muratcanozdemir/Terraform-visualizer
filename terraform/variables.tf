variable "vpc_id" {
  description = "The ID of the VPC where the ECS cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets in the VPC."
  type        = list(string)
}

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
  default     = "terraform-ecs-cluster"
}

variable "service_name" {
  description = "The name of the ECS service."
  type        = string
  default     = "terraform-service"
}

variable "task_memory" {
  description = "The amount of memory used by the task."
  type        = string
  default     = "512"
}

variable "task_cpu" {
  description = "The amount of CPU used by the task."
  type        = string
  default     = "256"
}

variable "docker_image" {
  description = "The Docker image URI."
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for the Route 53 record."
  type        = string
}

variable "hosted_zone_id" {
  description = "The ID of the Route 53 hosted zone."
  type        = string
}
