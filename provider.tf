# Specify the provider and access details
provider "aws" {
  shared_credentials_file = "/home/alan/.aws/credentials"
  profile                 = "p9"
  region                  = "${var.aws_region}"
}

