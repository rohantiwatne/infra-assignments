SHELL := /bin/bash

PROJECT := config-service
NAMESPACE := config-service
IMAGE := config-service:local
TERRAFORM_DIR := infra/terraform

.PHONY: all start bootstrap infra build load-image deploy validate smoke status logs destroy clean test fmt vet render

all: infra build load-image deploy validate

start:
	@echo "========================================="
	@echo " Starting Kubernetes Config Service"
	@echo "========================================="
	@echo ""
	@echo "[1/6] Bootstrapping local environment..."
	$(MAKE) bootstrap
	@echo ""
	@echo "[2/6] Provisioning infrastructure..."
	$(MAKE) infra
	@echo ""
	@echo "[3/6] Building application image..."
	$(MAKE) build
	@echo ""
	@echo "[4/6] Loading image into Minikube..."
	$(MAKE) load-image
	@echo ""
	@echo "[5/6] Deploying application..."
	$(MAKE) deploy
	@echo ""
	@echo "[6/6] Validating deployment..."
	$(MAKE) validate
	@echo ""
	@echo "========================================="
	@echo " Application started successfully!"
	@echo "========================================="
	@echo ""
	@echo "API endpoint:"
	@echo "  http://localhost:8080"
	@echo ""
	@echo "Start port-forward in another terminal:"
	@echo "  kubectl -n $(NAMESPACE) port-forward svc/$(PROJECT) 8080:8080"
	@echo ""
	@echo "Then test:"
	@echo "  curl http://localhost:8080/ping"
	@echo ""

bootstrap:
	./scripts/bootstrap.sh

infra:
	cd $(TERRAFORM_DIR) && terraform init
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

build:
	docker build -t $(IMAGE) ./app

load-image:
	minikube image load $(IMAGE)

deploy:
	./scripts/deploy.sh

validate:
	./scripts/smoke-test.sh

smoke: validate

status:
	kubectl -n $(NAMESPACE) get all
	kubectl -n $(NAMESPACE) get pvc,jobs

logs:
	kubectl -n $(NAMESPACE) logs deployment/$(PROJECT) --tail=200

test:
	cd app && go test ./...

fmt:
	cd app && gofmt -w $$(find . -name '*.go' -type f)

vet:
	cd app && go vet ./...

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve
	minikube delete

clean:
	rm -rf app/bin

render:
	kubectl kustomize k8s/overlays/local >/tmp/config-service-rendered.yaml
	@echo "Kustomize render written to /tmp/config-service-rendered.yaml"