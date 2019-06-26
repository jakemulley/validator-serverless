resource "aws_iam_role" "validator_fetch_master" {
  name               = "validator_fetch_master"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "validator_fetch_master" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:Scan",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "validator_fetch_master" {
  name = "validator_access_scheduler"
  path = "/"
  policy = data.aws_iam_policy_document.validator_fetch_master.json
}

resource "aws_iam_role_policy_attachment" "validator_access_scheduler" {
  role = aws_iam_role.validator_fetch_master.name
  policy_arn = aws_iam_policy.validator_fetch_master.arn
}
