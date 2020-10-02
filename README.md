# Simplified-Weather-Application-Infrastructure

This is just a simple staright forward creation of AWS resources in Terraform (i.e HCL) which are required in Simplified-Weather-Application.

What all is created using terraform? Please see below :
1) 3 Lambda functions 
2) 2 S3 Buckets
3) DynamoDB table 
4) API Gateway
5) Cloud Watch event
6) S3 object event

main.tf also includes IAM roles and policies which were required to execute Simplified-Weather-Application. 
The goal was to optimize and mminimize the human intervention, hence all the manual creation of services is done by main.tf
