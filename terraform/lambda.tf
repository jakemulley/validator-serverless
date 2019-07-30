provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_dir = "./scripts"
  output_path = "./handler.zip"
}

resource "aws_lambda_function" "validator_getMaster_lambda" {
  function_name = "validator_getMaster"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.ValidatorBrownfieldSites_iamrole.arn
  handler = "handler.getMaster"
  runtime = "nodejs10.x"
  description = "Fetches the master CSV for validators"
  timeout = 10
}

resource "aws_lambda_function" "validator_fetchTodaysResults_lambda" {
  function_name = "validator_fetchTodaysResults"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.ValidatorBrownfieldSites_iamrole.arn
  handler = "handler.fetchTodaysResults"
  runtime = "nodejs10.x"
  description = "Fetches todays validator results"
  timeout = 10
}

resource "aws_lambda_function" "validator_fetchOrganisationResults_lambda" {
  function_name = "validator_fetchOrganisationResults"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.ValidatorBrownfieldSites_iamrole.arn
  handler = "handler.fetchOrganisationResults"
  runtime = "nodejs10.x"
  description = "Fetches a specific organisations historical results"
  timeout = 10
}

resource "aws_lambda_function" "validator_retrieveFile_lambda" {
  function_name = "validator_retrieveFile"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.ValidatorBrownfieldSites_iamrole.arn
  handler = "handler.retrieveFile"
  runtime = "nodejs10.x"
  description = "Fetches a remote file and uploads it to S3"
  timeout = 10
}

resource "aws_lambda_function" "validator_validateFile_lambda" {
  function_name = "validator_validateFile"
  filename = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role = aws_iam_role.ValidatorBrownfieldSites_iamrole.arn
  handler = "handler.validateFile"
  runtime = "nodejs10.x"
  description = "Validates a stored file in DynamoDB"
  timeout = 10
}

# Give validateFile permission to execute itself from an S3 bucket event
resource "aws_lambda_permission" "validator_validateFile_lambda_permission" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validator_validateFile_lambda.arn
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.validator_brownfield_sites_s3.arn
}

# Fire off retrieveFile from a DynamoDB Stream event
resource "aws_lambda_event_source_mapping" "validator_retrieveFile_source" {
  batch_size = 1
  event_source_arn  = aws_dynamodb_table.validator_brownfield_sites_dynamodb.stream_arn
  enabled = true
  function_name     = aws_lambda_function.validator_retrieveFile_lambda.arn
  starting_position = "LATEST"
}
