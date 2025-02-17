# Terraform Lambda Go Example (2024-04-14)

This is a minimal Lambda example of deploying an HTTP API backed by an AWS Lambda function. The function is written in Go and deployment is automated with Terraform.

- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [References](#references)

## Prerequisites

### Terraform and Go

First install [Terraform][terraform] and [Go][golang]. 


[terraform]: https://www.terraform.io/
[golang]: https://www.terraform.io/

### AWS credentials

Configure your AWS access key and secret key with the `aws configure` command, or just create a file `~/.aws/credentials` containing the keys:

```
[default]
aws_access_key_id = KEY
aws_secret_access_key = KEY
```

The access key ID and the secret access key can be generated in the AWS management console.

### AWS region

The environment variable `AWS_DEFAULT_REGION` should be set to your favorite region. `us-west-2` would just work if you are not sure:

```console
$ export AWS_DEFAULT_REGION=us-west-2
```

This environment variable is used by the [Terraform AWS provider][terraform-aws].

[terraform-aws]: https://www.terraform.io/docs/providers/aws/

## Usage

Run `make` to build and deploy an API:

```console
$ make
```

In the process Terraform will ask you for a confirmation, so type `yes`. Everything should finish in less than a minute! After this you can play with the API:

```console
$ curl -fsSL $(terraform output -raw url)?name=world
Hello, world!
$ curl -fsSL $(terraform output -raw url)?name=lambda
Hello, lambda!
```

Cleanup:

```console
$ make clean
```

### About the Makefile

The Makefile is for convenience and does nothing special. It just runs following commands for you:

```console
$ terraform init
$ go get .
$ GOOS=linux GOARCH=arm64 go build -o bootstrap main.go
$ zip lambda-handler.zip bootstrap
$ terraform apply
$ terraform destroy
```

## References

### Lambda

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Building Lambda Functions](https://docs.aws.amazon.com/lambda/latest/dg/lambda-app.html)

### API Gateway

- [AWS API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)
- [Build an API Gateway API with Lambda Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/getting-started-with-lambda-integration.html)
- [Deploying an API in Amazon API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html)

### Terraform

- [Terraform AWS provider](https://www.terraform.io/docs/providers/aws/)


### Changelog
- References compiled and corrected by David González <leonardo.david.gonzalez@gmail.com> 
- Fixed to work with the arm64 architecture.
- Added Cloudwatch log information abour request and response. 
