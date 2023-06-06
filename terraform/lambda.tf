data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../src/ingestion-lambda-function-raw/ingestion-raw.py"
  output_path = "../src/ingestion-lambda-function-raw/ingestion-raw.zip"
}

resource "aws_lambda_function" "lambda-src-raw" {

  filename         = data.archive_file.lambda.output_path
  function_name    = "ingest-mvlens-raw"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "ingestion-raw.lambda_handler"
  timeout          = 900
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.10"


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

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      codebucket = "mv-lens-bucket"
    }
  }
}
