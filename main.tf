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

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "localopenweatherdata"

}

resource "aws_s3_bucket" "s3_bucket_2" {
  bucket = "simplifiedweatherapp"

}

resource "aws_s3_bucket" "s3_bucket_3" {
  bucket = "simplifiedweatherapp-test"
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

data "archive_file" "dummy"{
type= "zip"
output_path = "queryopenweatherapi-test.zip"
source {
content="hello"
filename="dummy.txt"
}
}

resource "aws_lambda_function" "example" {
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
