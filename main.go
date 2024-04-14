package main

import (
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"log"
)

// The input type and the output type are defined by the API Gateway.
func handleRequest(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	logStart(request)

	name, ok := request.QueryStringParameters["name"]
	if !ok {
		response := events.APIGatewayProxyResponse{
			StatusCode: http.StatusBadRequest,
		}
		logFinishError("El parámetro 'name' no existe.", response)
		return response, nil
	}

	response := events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "text/plain; charset=utf-8"},
		Body:       fmt.Sprintf("Hello, %s!\n", name),
	}

	logFinishOK(response)

	return response, nil
}

func main() {
	lambda.Start(handleRequest)
}

func logStart(request events.APIGatewayProxyRequest) {
	log.Printf("----------------------------------------------------------------------")
	log.Printf("API Start:")
	log.Printf("APIGatewayProxyRequest: [%s]", request.Body)
	log.Printf("QueryStringParameters: [%s]", request.QueryStringParameters)
}

func logFinishError(error_message string, response events.APIGatewayProxyResponse) {
	log.Printf("API Response: [%s]", response.Body)
	log.Printf("API Finish [ERROR]: %s", error_message)
	log.Printf("......................................................................")
}

func logFinishOK(response events.APIGatewayProxyResponse) {
	log.Printf("API Response: %s", response.Body)
	log.Printf("API Finish [OK].")
	log.Printf("......................................................................")
}
