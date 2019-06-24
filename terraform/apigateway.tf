resource "aws_api_gateway_rest_api" "validator_status_api" {
  name = "ValidatorStatusAPI"
  description = "Validator Status API"
}

resource "aws_api_gateway_resource" "validator_status_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.validator_status_api.id}"
  parent_id = "${aws_api_gateway_rest_api.validator_status_api.root_resource_id}"
  path_part = "status"
}

# Methods
resource "aws_api_gateway_method" "method" {
  rest_api_id = "${aws_api_gateway_rest_api.validator_status_api.id}"
  resource_id = "${aws_api_gateway_resource.validator_status_api_resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

# Integrations
resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${aws_api_gateway_rest_api.validator_status_api.id}"
  resource_id = "${aws_api_gateway_resource.validator_status_api_resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri = aws_lambda_function.validator_get_organisation_results.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "example_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.method",
    "aws_api_gateway_integration.integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.validator_status_api.id}"
  stage_name = "dev"
}

output "dev_url" {
  value = aws_api_gateway_deployment.example_deployment_dev.invoke_url
}
