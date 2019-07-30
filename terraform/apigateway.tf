resource "aws_api_gateway_rest_api" "ValidatorBrownfieldSites_api" {
  name = "Validator Brownfield Sites API"
  description = "Validator (Brownfield Sites) API (new)"
}

resource "aws_api_gateway_resource" "ValidatorBrownfieldSites_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.ValidatorBrownfieldSites_api.id
  parent_id = aws_api_gateway_rest_api.ValidatorBrownfieldSites_api.root_resource_id
  path_part = "status"
}

resource "aws_api_gateway_method" "ValidatorBrownfieldSites_api_method" {
  rest_api_id = aws_api_gateway_rest_api.ValidatorBrownfieldSites_api.id
  resource_id = aws_api_gateway_resource.ValidatorBrownfieldSites_api_resource.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ValidatorBrownfieldSites_api_integration" {
  rest_api_id = aws_api_gateway_rest_api.ValidatorBrownfieldSites_api.id
  resource_id = aws_api_gateway_resource.ValidatorBrownfieldSites_api_resource.id
  http_method = aws_api_gateway_method.ValidatorBrownfieldSites_api_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.validator_fetchTodaysResults_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "ValidatorBrownfieldSites_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ValidatorBrownfieldSites_api.id
  stage_name = "dev"
  depends_on = [
    "aws_api_gateway_method.ValidatorBrownfieldSites_api_method",
    "aws_api_gateway_integration.ValidatorBrownfieldSites_api_integration"
  ]
}

output "new_api_development_url" {
  value = aws_api_gateway_deployment.ValidatorBrownfieldSites_deployment.invoke_url
}

# Allow API Gateway to trigger a Lambda function
resource "aws_lambda_permission" "ValidatorBrownfieldSites_lambda_permission" {
  # The action this permission allows is to invoke the function
  action = "lambda:InvokeFunction"

  # The name of the lambda function to attach this permission to
  function_name = "${aws_lambda_function.validator_fetchTodaysResults_lambda.arn}"

  # An optional identifier for the permission statement
  statement_id = "AllowExecutionFromApiGateway"

  # The item that is getting this lambda permission
  principal = "apigateway.amazonaws.com"

  # /*/*/* sets this permission for all stages, methods, and resource paths in API Gateway to the lambda
  # function. - https://bit.ly/2NbT5V5
  source_arn = "${aws_api_gateway_rest_api.ValidatorBrownfieldSites_api.execution_arn}/*/*/*"
}

# TODO: Add more endpoints
