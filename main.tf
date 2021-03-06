provider "aws" {
  profile="default"
  region = "us-east-1"
}

## terraform backend bucket; Need to create this first manually
## and then continue with rest of the code

terraform {
 backend "s3" {
   bucket = "simplified-weather-application-infrastructure-state"
   key    = "default-infrastructure"
   region = "us-east-1"
 }
}

#### creating two S3 buckets ######
resource "aws_s3_bucket" "s3_bucket_1" {
  bucket = "localopenweatherdata"

}

resource "aws_s3_bucket" "s3_bucket_2" {
  bucket = "simplifiedweatherapp"
  acl = "public-read"
  website {
    index_document = "weather.html"
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {

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

########## IAM policy for logs ##############
resource "aws_iam_policy" "lambda_logging" {
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]

}
EOF

}
######### IAM policy for dynamoDB ###########
resource "aws_iam_policy" "lambda_dynamodb" {
  description = "An IAM policy that grants permissions policy grants permissions for all of the DynamoDB actions on a table"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Resource": [
        "arn:aws:dynamodb:::table/simplifiedopenweatherdata"
      ],
      "Effect": "Allow"
    }
  ]
}
POLICY

}
####################### First Lambda function #####################
data "archive_file" "dummy"{
type= "zip"
output_path = "queryopenweatherapi.zip"
source {
content="hello"
filename="dummy.txt"
}
}

resource "aws_lambda_function" "lambda_function_1" {
   function_name = "queryopenweatherapi"
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"
   filename= data.archive_file.dummy.output_path
   role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec-attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#### Adding Cloud Watch trigger for every hour

resource "aws_cloudwatch_event_rule" "hourlytrigger" {
  name                = "hourlytrigger"
  description         = "Fires every one hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "lambda_function_1_hourlytrigger" {
  rule      = aws_cloudwatch_event_rule.hourlytrigger.name
  target_id = "lambda_function_1"
  arn       = aws_lambda_function.lambda_function_1.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_function_1" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_1.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourlytrigger.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::308726405065:policy/service-role/AWSLambdaBasicExecutionRole-a488c18d-a021-43e1-8cd1-d1cc2d2db8e0"
}

####################### Second Lambda function #####################

data "archive_file" "dummy_dataextractor"{
type= "zip"
output_path = "dataextractor.zip"
source {
content="hello"
filename="dummy.txt"
}
}

resource "aws_lambda_function" "lambda_function_2" {
   function_name = "dataextractor"
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"
   filename= data.archive_file.dummy_dataextractor.output_path
   role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec-attach_2" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_2" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::308726405065:policy/service-role/AWSLambdaBasicExecutionRole-a488c18d-a021-43e1-8cd1-d1cc2d2db8e0"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb-attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_lambda_permission" "lambda_invoke" {
 statement_id  = "AllowS3Invoke"
 action        = "lambda:InvokeFunction"
 function_name = aws_lambda_function.lambda_function_2.function_name
 principal = "s3.amazonaws.com"
 source_arn = aws_s3_bucket.s3_bucket_1.arn
}

resource "aws_s3_bucket_notification" "s3-lambda-trigger" {
  bucket = aws_s3_bucket.s3_bucket_1.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function_2.arn
    events              = ["s3:ObjectCreated:*"]
    #filter_prefix       = "file-prefix"
    #filter_suffix       = "file-extension"
    }
    depends_on = [aws_lambda_permission.lambda_invoke]
}
####################### Third Lambda function #####################

data "archive_file" "dummy_querysimplifiedopenweatherdata"{
type= "zip"
output_path = "querysimplifiedopenweatherdata.zip"
source {
content="hello"
filename="dummy.txt"
}
}

resource "aws_lambda_function" "lambda_function_3" {
   function_name = "querysimplifiedopenweatherdata"
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"
   filename= data.archive_file.dummy_querysimplifiedopenweatherdata.output_path
   role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec-attach_3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::308726405065:policy/service-role/AWSLambdaBasicExecutionRole-a488c18d-a021-43e1-8cd1-d1cc2d2db8e0"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb-attach_2" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_api_gateway_rest_api" "myapi" {
  name        = "simplifiedopenweatherdata"
  description = "This is my API for lambda function"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowmyapiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_3.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.myapi.execution_arn}/*/*/*"
}
##################DynamoDB table #################
resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "simplifiedopenweatherdata"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "name"
    attribute {
      name = "name"
      type = "S"
  }
}
