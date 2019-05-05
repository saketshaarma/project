output "example_vpc" {
  value = "${aws_vpc.example_vpc.id}"
}

output "aws_public_subnet" {
  value = "${aws_subnet.example_public_subnet.*.cidr_block}"
}

output "aws_elb_hostname" {
  value = "${aws_elb.example_elb.dns_name}"
}
