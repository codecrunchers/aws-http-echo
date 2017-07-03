resource "aws_subnet" "pipeline_main" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.pipeline_vpc.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.pipeline_vpc.id}"
}

resource "aws_internet_gateway" "pipeline_gw" {
  vpc_id = "${aws_vpc.pipeline_vpc.id}"
}

resource "aws_route_table" "pipeline_rt" {
  vpc_id = "${aws_vpc.pipeline_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.pipeline_gw.id}"
  }
}

resource "aws_route_table_association" "pipeline_rta" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.pipeline_main.*.id, count.index)}"
  route_table_id = "${aws_route_table.pipeline_rt.id}"
}

