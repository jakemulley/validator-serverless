# CloudWatch Event Rules for retrieving master CSV
# Caveat: cron rules are UTC only
resource "aws_cloudwatch_event_rule" "ValidatorBrownfieldSites" {
  name = "ValidatorBrownfieldSitesGetMaster"
  description = "Validator (Brownfield Sites) - fetch master CSV file at 12am UTC every day"
  schedule_expression = "cron(0 0 * * ? *)"
  is_enabled = true
  depends_on = ["aws_lambda_function.validator_getMaster_lambda"]
}

# Associate events with functions
resource "aws_cloudwatch_event_target" "ValidatorBrownfieldSites_target" {
  rule = aws_cloudwatch_event_rule.ValidatorBrownfieldSites.name
  target_id = "ValidatorBrownfieldSites_target"
  arn = aws_lambda_function.validator_getMaster_lambda.arn
}

# Allow CloudWatch to invoke Lambda functions
resource "aws_lambda_permission" "ValidatorBrownfieldSites_AllowLambdaInvocation" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validator_getMaster_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.ValidatorBrownfieldSites.arn
}
