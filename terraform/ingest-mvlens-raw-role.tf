data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloud_watch_policy" {


  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:us-east-2:977746141011:*",
      "arn:aws:logs:us-east-2:977746141011:log-group:/aws/lambda/ingest-mvlens-raw:*",
    ]
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
      "s3-object-lambda:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "s3_policy" {
  name   = "s3_policy"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role_policy" "cloud_watch_policy" {
  name   = "cloud_watch_policy"
  policy = data.aws_iam_policy_document.cloud_watch_policy.json
  role   = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.s3_policy.arn
}