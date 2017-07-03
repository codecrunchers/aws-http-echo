output "instance_security_group" {
  value = "${aws_security_group.pipeline_instance_sg.id}"
}

output "launch_configuration" {
  value = "${aws_launch_configuration.pipeline_launch_config.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.pipeline_asgrp.id}"
}

output "alb_hostname" {
  value = "${aws_alb.pipeline_alb.dns_name}"
}
