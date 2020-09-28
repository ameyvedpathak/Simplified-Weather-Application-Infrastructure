provider "aws" {
  profile="default"
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "localopenweatherdata-test"

}
