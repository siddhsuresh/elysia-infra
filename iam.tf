data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role — used by the ECS agent to pull images and write logs
resource "aws_iam_role" "execution" {
  name               = "${local.prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = { Name = "${local.prefix}-ecs-execution" }
}

resource "aws_iam_role_policy_attachment" "execution_base" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role — assumed by the running container
resource "aws_iam_role" "task" {
  name               = "${local.prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = { Name = "${local.prefix}-ecs-task" }
}
