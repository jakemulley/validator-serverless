resource "aws_iam_role" "ValidatorBrownfieldSites_iamrole" {
  name = "validator_iam_role_lambda"
  assume_role_policy = file("json/assume-role-policy.json")
}

resource "aws_iam_policy" "ValidatorBrownfieldSites_iam_policy" {
  name = "validator_iam_policy"
  policy = data.aws_iam_policy_document.ValidatorBrownfieldSites_policy.json
  path = "/"
}

resource "aws_iam_role_policy_attachment" "ValidatorBrownfieldSites_iam_policy_attachment" {
  role = aws_iam_role.ValidatorBrownfieldSites_iamrole.name
  policy_arn = aws_iam_policy.ValidatorBrownfieldSites_iam_policy.arn
}

data "aws_iam_policy_document" "ValidatorBrownfieldSites_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
      "dynamodb:Query",
      "dynamodb:UpdateItem"
    ]

    resources = [
      aws_dynamodb_table.validator_brownfield_sites_dynamodb.arn,
      "${aws_dynamodb_table.validator_brownfield_sites_dynamodb.arn}/index/*",
      aws_dynamodb_table.validator_brownfield_sites_dynamodb.stream_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      "${aws_s3_bucket.validator_brownfield_sites_s3.arn}/*"
    ]
  }
}

# TODO: Split these out into more succinct roles
