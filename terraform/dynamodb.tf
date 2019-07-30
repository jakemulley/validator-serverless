# DynamoDB table for Validator (Brownfield Sites)
resource "aws_dynamodb_table" "validator_brownfield_sites_dynamodb" {
  name = "ValidatorBrownfieldSites"
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1
  hash_key = "date"
  range_key = "organisation"

  stream_enabled = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "date"
    type = "S"
  }

  attribute {
    name = "organisation"
    type = "S"
  }

  global_secondary_index {
    name               = "OrganisationDateIndex"
    hash_key           = "organisation"
    range_key          = "date"
    write_capacity     = 1
    read_capacity      = 1
    projection_type    = "ALL"
  }
}

# end new Dynamodb - do not destroy until after data migration
