variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name tag and prefix"
  type        = string
  default     = "smartcity-ai-platform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.small"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key used to access the EC2 instance"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block permitted for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ai_api_key" {
  description = "Gemini / AI API key for chat endpoints"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ai_model" {
  description = "AI model identifier"
  type        = string
  default     = "gemini-2.5-flash"
}
