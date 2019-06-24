resource "aws_dynamodb_table" "validator_serverless_dynamodb" {
  name             = "ValidatorServerless"
  billing_mode     = "PROVISIONED"
  read_capacity    = 10
  write_capacity   = 10
  hash_key         = "hash"

  # Allow streams to enable validation immediately after item entry
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "hash"
    type = "S"
  }
}
