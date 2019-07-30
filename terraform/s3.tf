resource "aws_s3_bucket" "validator_brownfield_sites_s3" {
  bucket = "validatorbrownfieldsites"
  acl =  "private"
}

resource "aws_s3_bucket_notification" "validator_brownfield_sites_s3_notification" {
  bucket = aws_s3_bucket.validator_brownfield_sites_s3.id
  lambda_function {
    lambda_function_arn =  aws_lambda_function.validator_validateFile_lambda.arn
    events = ["s3:ObjectCreated:*"]
  }
}
