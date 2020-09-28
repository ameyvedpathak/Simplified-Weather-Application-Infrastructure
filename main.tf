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
