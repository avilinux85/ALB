resource "aws_lb_target_group" "target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name        = "test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_lb" "alb" {
  name               = "test-alb"
  internal           = false
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG_LB.id]
  subnets            = [sort(data.aws_subnets.all.ids)[0],sort(data.aws_subnets.all.ids)[1]]
}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2-attach1" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.lb1_ec2.id
}

resource "aws_lb_target_group_attachment" "ec2-attach2" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.lb2_ec2.id
}
