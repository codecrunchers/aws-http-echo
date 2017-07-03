## ALB

resource "aws_alb_target_group" "pipeline_echo_tg" {
  name     = "pipeline-echo"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.pipeline_vpc.id}"
}

resource "aws_alb" "pipeline_alb" {
  name            = "pipeline-alb-ecs"
  subnets         = ["${aws_subnet.pipeline_main.*.id}"]
  security_groups = ["${aws_security_group.pipeline_lb_sg.id}"]
}

resource "aws_alb_listener" "pipeline_alb_listener" {
  load_balancer_arn = "${aws_alb.pipeline_alb.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.pipeline_echo_tg.id}"
    type             = "forward"
  }
}


