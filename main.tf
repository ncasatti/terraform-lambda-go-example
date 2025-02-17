# This is required to get the AWS region via ${data.aws_region.current}.
data "aws_region" "current" {
}

# A Lambda function may access to other AWS resources such as S3 bucket. So an
# IAM role needs to be defined. This hello world example does not access to
# any resource, so the role is empty.
#
# The date 2012-10-17 is just the version of the policy language used here [1].
#
# [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_version.html
resource "aws_iam_role" "hello" {
  name               = "hello"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow"
  }
}
POLICY
}

resource "aws_iam_policy" "function_logging_policy" {
  name   = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.hello.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}


# Define a Lambda function.
#
# The handler is the name of the executable for go1.x runtime.
resource "aws_lambda_function" "hello" {
  function_name    = "hello"
  filename         = "lambda-handler.zip"
  handler          = "bootstrap"
  source_code_hash = filebase64sha256("./lambda-handler.zip")
  role             = aws_iam_role.hello.arn
  runtime          = "provided.al2023"
  architectures = ["arm64"]                    # arquitetura arm arm64
  memory_size      = 128
  timeout          = 30
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.hello.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}


# Allow API gateway to invoke the hello Lambda function.
resource "aws_lambda_permission" "hello" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.arn
  principal     = "apigateway.amazonaws.com"
}

# A Lambda function is not a usual public REST API. We need to use AWS API
# Gateway to map a Lambda function to an HTTP endpoint.
resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.hello.id
  parent_id   = aws_api_gateway_rest_api.hello.root_resource_id
#  path_part   = "hello"
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_rest_api" "hello" {
  name = "hello"
}

#           GET
# Internet -----> API Gateway
resource "aws_api_gateway_method" "hello" {
  rest_api_id   = aws_api_gateway_rest_api.hello.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}

#              POST
# API Gateway ------> Lambda
# For Lambda the method is always POST and the type is always AWS_PROXY.
#
# The date 2015-03-31 in the URI is just the version of AWS Lambda.
#resource "aws_api_gateway_integration" "hello" {
#  rest_api_id             = aws_api_gateway_rest_api.hello.id
#  resource_id             = aws_api_gateway_resource.hello.id
#  http_method             = aws_api_gateway_method.hello.http_method
#  integration_http_method = "POST"
#  type                    = "AWS_PROXY"
#  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello.arn}/invocations"
#}

resource "aws_api_gateway_integration" "hello" {
   rest_api_id = aws_api_gateway_rest_api.hello.id
   resource_id = aws_api_gateway_method.hello.resource_id
   http_method = aws_api_gateway_method.hello.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.hello.invoke_arn
}

# This resource defines the URL of the API Gateway.
resource "aws_api_gateway_deployment" "hello_v1" {
  depends_on = [
    aws_api_gateway_integration.hello
  ]
  rest_api_id = aws_api_gateway_rest_api.hello.id
  stage_name  = "v1"
}

# Set the generated URL as an output. Run `terraform output url` to get this.
output "url" {
  value = "${aws_api_gateway_deployment.hello_v1.invoke_url}${aws_api_gateway_resource.hello.path}"
}
