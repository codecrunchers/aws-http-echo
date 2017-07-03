resource "aws_autoscaling_group" "pipeline_asgrp" {
  name                 = "pipeline-asgrp"
  vpc_zone_identifier  = ["${aws_subnet.pipeline_main.*.id}"]
  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.pipeline_launch_config.name}"
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml")}"

  vars {
    aws_region         = "${var.aws_region}"
    ecs_cluster_name   = "${aws_ecs_cluster.pipeline_ecs_cluster.name}"
    ecs_log_level      = "info"
    ecs_agent_version  = "latest"
    ecs_log_group_name = "${aws_cloudwatch_log_group.pipeline_cw_lg.name}"
  }
}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

resource "aws_launch_configuration" "pipeline_launch_config" {
  security_groups = [
    "${aws_security_group.pipeline_instance_sg.id}",
  ]

#  key_name                    = "${var.key_name}"
  image_id                    = "${data.aws_ami.stable_coreos.id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.pipeline_app_instance_profile.name}"
  user_data                   = "${data.template_file.cloud_config.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "echo_task_definition_file" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    image_url        = "kennship/http-echo:latest"
    container_name   = "echo"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.pipeline_app_lg.name}"
  }
}

resource "aws_ecs_task_definition" "echo" {
  family                = "echo_family"
  container_definitions = "${data.template_file.echo_task_definition_file.rendered}"
}

resource "aws_ecs_service" "pipeline_echo_service" {
  name            = "echo_service"
  cluster         = "${aws_ecs_cluster.pipeline_ecs_cluster.id}"
  task_definition = "${aws_ecs_task_definition.echo.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.pipeline_ecs_service_role.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.pipeline_echo_tg.id}"
    container_name   = "echo"
    container_port   = "3000"
  }

  depends_on = [
    "aws_iam_role_policy.pipeline_ecs_service_role",
    "aws_alb_listener.pipeline_alb_listener",
  ]
}


data "template_file" "instance_profile" {
  template = "${file("${path.module}/instance-profile-policy.json")}"

  vars {
    app_log_group_arn = "${aws_cloudwatch_log_group.pipeline_app_lg.arn}"
    ecs_log_group_arn = "${aws_cloudwatch_log_group.pipeline_cw_lg.arn}"
  }
}

resource "aws_iam_role_policy" "pipeline_instance_role_policy" {
  name   = "TfEcsExampleInstanceRole"
  role   = "${aws_iam_role.pipeline_app_instance_role.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "pipeline_cw_lg" {
  name = "pipeline-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "pipeline_app_lg" {
  name = "pipeline-ecs-group/app-echo"
}
