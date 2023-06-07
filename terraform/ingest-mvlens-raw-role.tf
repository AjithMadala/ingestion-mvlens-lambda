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

data "aws_iam_policy_document" "sns_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sns:*"
    ]

    resources = [
      "*"
    ]
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


resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name        = "movielens-scheduled-rule"
  description = "Scheduled rule to trigger moviele ns Lambda function"

  schedule_expression = "cron(0 12 * * ? *)"  # Change to your desired schedule

  tags = {
    Environment = "Production"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule.name
  arn       = aws_lambda_function.lambda-src-raw.arn
  target_id = "my-lambda-target"
}

resource "aws_iam_role_policy" "sns_policy_attachment" {
  name   = "sns_policy_attachment"
  policy = data.aws_iam_policy_document.sns_policy.json
  role   = aws_iam_role.iam_for_lambda.name
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = "arn:aws:sns:us-east-2:977746141011:data-pipeline-notfication"
  protocol  = "email-json"
  endpoint  = "madala.ajith111@gmail.com"
}