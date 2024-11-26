resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:DescribeParameters"
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/encryption_key",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/strava_callback_state",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/strava_client_id",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/strava_client_secret",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/webhook_subscription_id",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/webhook_verify_token",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/users"
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-policy-attachment"
  policy_arn = resource.aws_iam_policy.lambda_policy.arn
  roles      = [aws_iam_role.lambda_execution_role.name]
}