.PHONY: test clean

test: deploy.done
	curl -fsSL -D - "$$(terraform output -raw url)?name=Lambda"

clean:
	terraform destroy
	rm -f init.done deploy.done lambda-handler.zip bootstrap

init.done:
	terraform init
	touch $@

deploy.done: init.done main.tf hello.zip
	terraform apply
	touch $@

hello.zip: hello
	zip lambda-handler.zip bootstrap

hello: main.go
	go get .
	GOOS=linux GOARCH=arm64 go build -o bootstrap main.go
