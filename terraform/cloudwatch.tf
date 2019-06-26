# CloudWatch Event Rules for retrieving master CSV
# Caveat: cron rules are UTC only

resource "aws_cloudwatch_event_rule" "validator_brownfield_schedule_fetch_master" {
  name = "validator-brownfield-fetch-master"
  description = "Validator - fetch master CSV file at 12am UTC every day"
  schedule_expression = "cron(0 0 * * ? *)"
  is_enabled = true
  depends_on = ["aws_lambda_function.validator_fetch_master"]
}

# Associate events with functions
resource "aws_cloudwatch_event_target" "validator_brownfield_schedule_fetch_master_target" {
  rule = aws_cloudwatch_event_rule.validator_brownfield_schedule_fetch_master.name
  target_id = "validator_brownfield_schedule_fetch_master_target"
  arn = aws_lambda_function.validator_fetch_master.arn
}

# Allow CloudWatch to invoke Lambda functions
resource "aws_lambda_permission" "validator_schedule_allow_cloudwatch_lambda" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validator_fetch_master.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.validator_brownfield_schedule_fetch_master.arn
}
