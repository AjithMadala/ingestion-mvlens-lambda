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


  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      codebucket = "mv-lens-bucket"
    }
  }
}
