provider "aws" {
  profile="default"
  region = "us-east-1"
}

terraform {
 backend "s3" {
   bucket = "simplified-weather-application-infrastructure-state"
   key    = "default-infrastructure"
   region = "us-east-1"
 }
}

resource "aws_s3_bucket" "s3_bucket_101" {
  bucket = "localopenweatherdata"

}

resource "aws_s3_bucket" "s3_bucket_102" {
  bucket = "simplifiedweatherapp"

}

resource "aws_s3_bucket" "s3_bucket_1" {
  bucket = "localopenweatherdata-test"

}

resource "aws_s3_bucket" "s3_bucket_2" {
  bucket = "simplifiedweatherapp-test"
  acl = "public-read"
  website {
    index_document = "weather.html"
  }
}

/*
resource "aws_s3_bucket_policy" "s3_bucket_2" {
  bucket = aws_s3_bucket.s3_bucket_2.id

  policy = <<POLICY
  {
      "Version": "2008-10-17",
      "Id": "PolicyForPublicWebsiteContent",
      "Statement": [
          {
              "Sid": "PublicReadGetObject",
              "Effect": "Allow",
              "Principal": {
                  "AWS": "*"
              },
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::simplifiedweatherapp-test/*"
          }
      ]
  }
POLICY
}
*/

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

data "archive_file" "dummy"{
type= "zip"
output_path = "queryopenweatherapi-test.zip"
source {
content="hello"
filename="dummy.txt"
}
}

resource "aws_lambda_function" "lambda_function_1" {
   function_name = "queryopenweatherapi-test"
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"
   filename= data.archive_file.dummy.output_path
   role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec-attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#####################################


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

##########################################

data "archive_file" "dummy_dataextractor"{
type= "zip"
output_path = "dataextractor-test.zip"
source {
content="hello"
filename="dummy.txt"
}
}

resource "aws_lambda_function" "lambda_function_2" {
   function_name = "dataextractor-test"
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
###################################################

resource "aws_s3_bucket_notification" "s3-lambda-trigger" {
bucket = aws_s3_bucket.s3_bucket_1.bucket #"${aws_s3_bucket.bucket.id}"
lambda_function {
lambda_function_arn = aws_lambda_function.lambda_function_2.arn"
events              = ["s3:ObjectCreated:*"]
filter_prefix       = "file-prefix"
filter_suffix       = "file-extension"
}
}
resource "aws_lambda_permission" "lambda_invoke" {
statement_id  = "AllowS3Invoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.test_lambda.function_name
principal = "s3.amazonaws.com"
source_arn = "arn:aws:s3:::aws_s3_bucket.s3_bucket_1.id"
}
