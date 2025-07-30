variable "tags" {
  type = map(string)
  default = {
    Project     = "workshop-devops-na-nuvem"
    Environment = "production"
  }
}

variable "auth" {
  type = object({
    assume_role_arn = string
    region          = string
  })

  default = {
    assume_role_arn = "arn:aws:iam::148761658767:role/assume-role-terraform"
    region          = "us-east-1"
  }
}