## Network

data "aws_availability_zones" "available" {}

resource "aws_vpc" "pipeline_vpc" {
  cidr_block = "10.10.0.0/16"
}

