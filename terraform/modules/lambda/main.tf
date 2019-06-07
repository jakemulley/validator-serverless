provider "aws" {
  region = "eu-west-2"
}

data "archive_file" "zip" {
  type = "zip"
  source_dir = "./lambda_function"
  output_path = "./lambda_function/handler.js.zip"
}

resource "aws_lambda_function" "validator_serverless_lambda" {
  filename = data.archive_file.zip.output_path
  function_name = "validator_serverless_lambda"
  role = aws_iam_role.validator_serverless_api_role.arn
  handler = "handler.handler"
  runtime = "nodejs10.x"
  source_code_hash = filebase64sha256(data.archive_file.zip.output_path)
}

resource "aws_iam_role" "validator_serverless_api_role" {
  name = "validator_serverless_api_role"
  assume_role_policy = file("lambdaRole.json")
}

resource "aws_iam_role_policy" "validator_serverless_policy" {
  name = "iam-lambda-policy"
  role = "${aws_iam_role.validator_serverless_api_role.id}"
  policy = file("lambdaPolicy.json")
}

resource "aws_lambda_permission" "allow_api_gateway" {
  # The action this permission allows is to invoke the function
  action = "lambda:InvokeFunction"

  # The name of the lambda function to attach this permission to
  function_name = "${aws_lambda_function.validator_serverless_lambda.arn}"

  # An optional identifier for the permission statement
  statement_id = "AllowExecutionFromApiGateway"

  # The item that is getting this lambda permission
  principal = "apigateway.amazonaws.com"

  # /*/*/* sets this permission for all stages, methods, and resource paths in API Gateway to the lambda
  # function. - https://bit.ly/2NbT5V5
  source_arn = "${aws_api_gateway_rest_api.validator_serverless_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_rest_api" "validator_serverless_api" {
  name = "Validator Serverless API"
  description = "A proof of concept for an API to return whether a dataset is valid or not"
}

resource "aws_api_gateway_resource" "validator_serverless_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.validator_serverless_api.id}"
  parent_id = "${aws_api_gateway_rest_api.validator_serverless_api.root_resource_id}"
  path_part = "messages"
}

resource "aws_api_gateway_method" "validator_serverless_method" {
  rest_api_id = "${aws_api_gateway_rest_api.validator_serverless_api.id}"
  resource_id = "${aws_api_gateway_resource.validator_serverless_resource.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "validator_serverless_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.validator_serverless_api.id}"
  resource_id = "${aws_api_gateway_resource.validator_serverless_resource.id}"
  http_method = "${aws_api_gateway_method.validator_serverless_method.http_method}"
  type = "AWS_PROXY"
  uri = aws_lambda_function.validator_serverless_lambda.invoke_arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "validator_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.validator_serverless_method",
    "aws_api_gateway_integration.validator_serverless_integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.validator_serverless_api.id}"
  stage_name = "dev"
}

output "dev_url" {
  value = aws_api_gateway_deployment.validator_deployment_dev.invoke_url
}
