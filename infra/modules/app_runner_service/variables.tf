variable "supabase_url_ssm_arn" {
  type        = string
  description = "SSM ARN with Supabase URL"
}

variable "supabase_anon_key_ssm_arn" {
  type        = string
  description = "SSM ARN with Supabase anon key"
}

variable "openai_api_key_ssm_arn" {
  type        = string
  description = "SSM ARN with OpenAI API key"
}

