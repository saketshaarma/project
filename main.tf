provider "aws" {
  secret_key = "${var.aws_secret_key}"
  access_key = "${var.aws_access_key}"
  region = "${var.aws_region}"
}
resource "aws_vpc" "example_vpc" {
  cidr_block = "${var.aws_vpc_cidr}"
  enable_dns_support = true
  tags {
    Name="example_vpc"
  }
}

data "aws_availability_zones" "all" {}

resource "aws_subnet" "example_public_subnet" {
  count = "${length(data.aws_availability_zones.all.names)}"
  availability_zone = "${data.aws_availability_zones.all.names[count.index]}"
  cidr_block = "${cidrsubnet(var.aws_vpc_cidr,8,count.index)}"
  vpc_id = "${aws_vpc.example_vpc.id}"
  map_public_ip_on_launch = true
  tags {
    Name="example_public_subnet"
  }
}

resource "aws_subnet" "example_private_subnet" {
  count = "${length(data.aws_availability_zones.all.names)}"
  availability_zone = "${data.aws_availability_zones.all.names[count.index]}"
  cidr_block = "${cidrsubnet(var.aws_vpc_cidr,8,length(data.aws_availability_zones.all.id)+count.index)}"
  vpc_id = "${aws_vpc.example_vpc.id}"
  map_public_ip_on_launch = false
  tags {
    Name="example_private_subnet"
  }
  depends_on = ["aws_subnet.example_public_subnet"]
}

resource "aws_internet_gateway" "example_inter_gw" {
  vpc_id = "${aws_vpc.example_vpc.id}"
  tags {
    Name="example_vpc_internet_gateway"
  }
}


resource "aws_route_table" "example_vpc_route_table_public" {
  vpc_id = "${aws_vpc.example_vpc.id}"
  route {
    cidr_block = "${var.public_cidr}"
    gateway_id = "${aws_internet_gateway.example_inter_gw.id}"
  }
  tags {
    Name="example_vpc_route_table_public"
  }
}

resource "aws_route_table_association" "example_public_route_table" {
  count = "${length(data.aws_availability_zones.all.names)}"
  route_table_id = "${aws_route_table.example_vpc_route_table_public.id}"
  subnet_id = "${element(aws_subnet.example_public_subnet.*.id,count.index)}"
}
resource "aws_route" "public_internet_gw" {
  route_table_id = "${aws_route_table.example_vpc_route_table_public.id}"
  destination_cidr_block = "${var.public_cidr}"
  gateway_id = "${aws_internet_gateway.example_inter_gw.id}"
}
resource "aws_eip" "example_eip_nat_gw" {
  vpc = true
  count = "${length(data.aws_availability_zones.all.names)}"
  tags {
    Name="example_eip_nat_gw.${count.index}"
  }
}

resource "aws_nat_gateway" "example_nat_gw" {
  count = "${length(data.aws_availability_zones.all.names)}"
  allocation_id = "${element(aws_eip.example_eip_nat_gw.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.example_public_subnet.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.example_inter_gw"]
}

resource "aws_route_table" "example_vpc_route_table_private" {
  vpc_id = "${aws_vpc.example_vpc.id}"
  route {
    cidr_block = "${var.public_cidr}"
    nat_gateway_id = "${element(aws_nat_gateway.example_nat_gw.*.id, count.index)}"
  }
  tags {
    Name="example_vpc_route_table_private"
  }
}
resource "aws_route_table_association" "example_rt_private_pool" {
  count = "${length(data.aws_availability_zones.all.names)}"
  route_table_id = "${aws_route_table.example_vpc_route_table_private.id}"
  subnet_id = "${element(aws_subnet.example_private_subnet.*.id, count.index)}"
}

resource "aws_key_pair" "example_key" {
  public_key = "${var.aws_key_pair_public}"
  key_name = "${var.aws_key_name}"
}

resource "aws_launch_configuration" "example_launch_config" {

  image_id = "${var.aws_instance_iamge}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.example_key.id}"
  security_groups = ["${aws_security_group.example_security_group_ec2.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "example_security_group_ec2" {
  vpc_id = "${aws_vpc.example_vpc.id}"
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["${var.public_cidr}"]
  }
  ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    security_groups = ["${aws_security_group.example_security_group_lb.id}"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["${var.public_cidr}"]
  }
  tags {
    Name="security_group_ec2_instance"
  }
}

resource "aws_security_group" "example_security_group_lb" {
  vpc_id = "${aws_vpc.example_vpc.id}"
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["${var.public_cidr}"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["${var.public_cidr}"]
  }
  tags {
    Name="Security_group_elb"
  }
}

resource "aws_autoscaling_group" "example_asg" {
  max_size = 5
  min_size = 1
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  force_delete = true
  health_check_grace_period = 300
  launch_configuration = "${aws_launch_configuration.example_launch_config.id}"
  desired_capacity = 1
  vpc_zone_identifier = ["${element(aws_subnet.example_public_subnet.*.id,count.index)}"]
  load_balancers = ["${aws_elb.example_elb.id}"]
  timeouts {
    delete = "15m"
  }
}
resource "aws_elb" "example_elb" {
  subnets = ["${element(aws_subnet.example_public_subnet.*.id,count.index)}"]
  security_groups = ["${aws_security_group.example_security_group_lb.id}"]
  cross_zone_load_balancing = true
  health_check {
    healthy_threshold = 2
    interval = 30
    target = "HTTP:8080/"
    timeout = 3
    unhealthy_threshold = 2
  }
  "listener" {
    instance_port = 8080
    instance_protocol = "tcp"
    lb_port = 80
    lb_protocol = "tcp"
  }
}
