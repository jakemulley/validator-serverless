provider "archive" {}

# ZIP of the Lambda scripts
data "archive_file" "zip" {
  type        = "zip"
  source_dir = "./scripts"
  output_path = "./handler.zip"
}

# Lambda functions
resource "aws_lambda_function" "validator_fetch_master" {
  function_name = "validator_fetch_master"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.validator_fetch_master.arn
  handler = "handler.getMaster"
  runtime = "nodejs10.x"
  description = "Fetches the master CSV for brownfield sites validator"
  timeout = 30
}

resource "aws_lambda_function" "validator_validate_item" {
  function_name = "validator_validate_item"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.validator_fetch_master.arn
  handler = "handler.validate"
  runtime = "nodejs10.x"
  description = "Validates a row in DynamoDB"
  timeout = 30
}

resource "aws_lambda_function" "validator_get_organisation_results" {
  function_name = "validator_get_organisation_results"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.validator_fetch_master.arn
  handler = "handler.getOrgResults"
  runtime = "nodejs10.x"
  description = "Gets organisations or an organisation result from DynamoDB"
  timeout = 30
}

# Lambda Permissions
resource "aws_lambda_permission" "allow_api_gateway" {
  # The action this permission allows is to invoke the function
  action = "lambda:InvokeFunction"

  # The name of the lambda function to attach this permission to
  function_name = "${aws_lambda_function.validator_get_organisation_results.arn}"

  # An optional identifier for the permission statement
  statement_id = "AllowExecutionFromApiGateway"

  # The item that is getting this lambda permission
  principal = "apigateway.amazonaws.com"

  # /*/*/* sets this permission for all stages, methods, and resource paths in API Gateway to the lambda
  # function. - https://bit.ly/2NbT5V5
  source_arn = "${aws_api_gateway_rest_api.validator_status_api.execution_arn}/*/*/*"
}

# Event source mapping
resource "aws_lambda_event_source_mapping" "validator_validate_item_source" {
  event_source_arn  = aws_dynamodb_table.validator_serverless_dynamodb.stream_arn
  function_name     = aws_lambda_function.validator_validate_item.arn
  starting_position = "LATEST"
  batch_size        = 1
}
