provider "aws" {
  region = "eu-west-2"
}

module "validator-serverless-lambda" {
  source              = "./modules/lambda"
# #   name                = "Proof of concept application for Validator"
# #   identifier          = "POC-VALIDATOR"
# #   business_unit       = "Digital Land"
# #   budget_holder_email = "jake.mulley@communities.gov.uk"
# #   tech_contact_email  = "jake.mulley@communities.gov.uk"
# #   stage               = "dev"
}

# module "validator-serverless-apigateway" {
#   source              = "./modules/apigateway"
#   # name                = "Proof of concept application for Validator"
#   # identifier          = "POC-VALIDATOR"
#   # business_unit       = "Digital Land"
#   # budget_holder_email = "jake.mulley@communities.gov.uk"
#   # tech_contact_email  = "jake.mulley@communities.gov.uk"
#   # stage               = "dev"
# }

# # module "validator-serverless-dynamodb" {
# #   source              = "./modules/dynamodb.tf"
# #   name                = "Proof of concept application for Validator"
# #   identifier          = "POC-VALIDATOR"
# #   business_unit       = "Digital Land"
# #   budget_holder_email = "jake.mulley@communities.gov.uk"
# #   tech_contact_email  = "jake.mulley@communities.gov.uk"
# #   stage               = "dev"
# # }
