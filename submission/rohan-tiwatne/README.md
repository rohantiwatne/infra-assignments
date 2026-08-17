# Kubernetes Config Service

A small, reproducible **Go-based configuration service** deployed to a local Kubernetes environment.

This repository was created to satisfy the Infrastructure Engineering Assignment requirements around:

* Go HTTP application development
* PostgreSQL persistence
* Infrastructure as Code
* Kubernetes deployment
* Local reproducibility
* Configuration and secret management
* Health checks and operational readiness
* Deployment automation
* Smoke/integration validation
* Reviewer-oriented documentation

The implementation intentionally stays small while demonstrating production-style engineering decisions.

---

# 1. Assignment Summary

The assignment asks for a local Kubernetes configuration service containing:

1. A Go application exposing:

   * `GET /ping`
   * `GET /configs/:id`
   * `POST /configs`

2. A PostgreSQL database.

3. Infrastructure provisioning through Terraform or an equivalent IaC mechanism.

4. Kubernetes deployment configuration.

5. Repeatable local bootstrap and deployment automation.

6. Documentation covering:

   * Architecture
   * Configuration and secrets
   * Health checks
   * Persistence
   * Deployment
   * Operational assumptions
   * Validation
   * Known limitations

7. Testing and operational evidence.

This repository implements all of the above with a deliberately small technology footprint.

---

# 2. Getting Started

The application can be installed and started locally with just **two commands**.

The `install.sh` script automatically handles all required prerequisites and installation steps.

## Step 1 — Clone the Repository

```bash
git clone https://github.com/Robustrade/infra-assignments.git
```

## Step 2 — Navigate to the Solution Directory

```bash
cd infra-assignments/submission/solution/rohan-tiwatne
```

> **Important:** The following commands must be executed from the `solution/rohan-tiwatne` directory.

## Step 3 — Install the Application

Run:

```bash
./install.sh
```

The installation script automatically checks and installs the required prerequisites and performs the necessary setup for the application.

## Step 4 — Start the Application

Run:

```bash
make start
```

The application will be deployed to the local Kubernetes environment.

After `make start` completes, the terminal will display the command required to access the service locally.

Run the following command in **another terminal**:

```bash
kubectl -n config-service port-forward svc/config-service 8080:8080
```

You should see output similar to:

```text
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
```

The application is now available locally at:

```text
http://localhost:8080
```

> Keep the port-forward command running while testing the application.

---

# 3. Quick Start

After cloning the repository:

```bash
cd infra-assignments/submission/solution/rohan-tiwatne
./install.sh
make start
```

Then, in another terminal:

```bash
kubectl -n config-service port-forward svc/config-service 8080:8080
```

The service will be available at:

```text
http://localhost:8080
```

---

# 4. Using the Application

The service exposes the following REST APIs.

## Health Check

Use the `/ping` endpoint to verify that the application is running:

```bash
curl http://localhost:8080/ping
```

A successful response confirms that the application is reachable.

## Create a Configuration

Create a configuration using:

```bash
curl -X POST http://localhost:8080/configs \
  -H "Content-Type: application/json" \
  -d '{
    "key": "example",
    "value": "hello-world"
  }'
```

The service will persist the configuration in PostgreSQL.

## Retrieve a Configuration

Use the configuration ID returned when creating the configuration:

```bash
curl http://localhost:8080/configs/<id>
```

Replace `<id>` with the ID of the configuration you want to retrieve.

---

# 5. Application Flow

```text
                    Clone Repository
                           |
                           v
              solution/rohan-tiwatne
                           |
                           v
                     ./install.sh
                           |
                           |-- Install prerequisites
                           |-- Prepare local environment
                           |-- Configure dependencies
                           |
                           v
                      make start
                           |
                           |-- Provision infrastructure
                           |-- Deploy PostgreSQL
                           |-- Deploy Config Service
                           |-- Run health checks
                           |
                           v
                 Kubernetes Environment
                           |
                           v
              kubectl port-forward
                           |
                           v
                  localhost:8080
                           |
                           v
                Test REST API Endpoints
```

---

# 6. Architecture

The application consists of a small set of components running in the local Kubernetes environment:

```text
                    Local Machine
                         |
                         | Port Forward
                         | :8080
                         v
                +-------------------+
                |   Config Service   |
                |      Go API        |
                +---------+---------+
                          |
                          |
                          v
                +-------------------+
                |    PostgreSQL      |
                |     Database       |
                +-------------------+
```

The Go application provides the HTTP API, while PostgreSQL provides persistent storage for configuration data.

Kubernetes is responsible for running and managing the application and database workloads.

---

# 7. Configuration and Secrets

Application configuration and sensitive values are managed through Kubernetes configuration and secret mechanisms rather than being hard-coded into the application.

The deployment configuration provides the required environment variables and database connection details to the application at runtime.

Sensitive credentials should not be committed to source control.

---

# 8. Health Checks and Operational Readiness

The application provides a health endpoint through:

```text
GET /ping
```

This endpoint can be used to verify application availability and is also suitable for Kubernetes health/readiness checks.

The deployment configuration is designed to ensure that the application is considered ready only when the required dependencies are available.

---

# 9. Persistence

PostgreSQL is used as the persistent data store for configuration information.

Configuration data created through:

```text
POST /configs
```

is persisted in PostgreSQL and can subsequently be retrieved using:

```text
GET /configs/:id
```

This demonstrates persistence beyond the lifecycle of an individual HTTP request.

---

# 10. Infrastructure as Code

Infrastructure and Kubernetes resources are defined using declarative configuration.

The infrastructure setup is designed to be repeatable so that the local environment can be recreated consistently.

The installation and deployment workflow is automated through:

```bash
./install.sh
```

and:

```bash
make start
```

---

# 11. Validation

The application can be validated using the following basic flow:

### 1. Start the application

```bash
make start
```

### 2. Enable local access

```bash
kubectl -n config-service port-forward svc/config-service 8080:8080
```

### 3. Verify application health

```bash
curl http://localhost:8080/ping
```

### 4. Create a configuration

```bash
curl -X POST http://localhost:8080/configs \
  -H "Content-Type: application/json" \
  -d '{
    "key": "example",
    "value": "hello-world"
  }'
```

### 5. Retrieve the configuration

```bash
curl http://localhost:8080/configs/<id>
```

This validates the complete request flow from the HTTP API through the application and into PostgreSQL persistence.

---

# 12. Stopping the Application

To stop the port forwarding, press:

```text
Ctrl + C
```

in the terminal running:

```bash
kubectl -n config-service port-forward svc/config-service 8080:8080
```

If a `make stop` target is available, the application can be stopped using:

```bash
make stop
```

---

# 13. Troubleshooting

## Application is not accessible

Make sure:

1. `make start` completed successfully.
2. The Kubernetes resources are running.
3. The `config-service` service exists.
4. The port-forward command is still running.

Check the service:

```bash
kubectl -n config-service get svc
```

Check the pods:

```bash
kubectl -n config-service get pods
```

Start the port forwarding again if required:

```bash
kubectl -n config-service port-forward svc/config-service 8080:8080
```

## Port 8080 is already in use

If port `8080` is already being used by another application, stop the process using the port or use another local port:

```bash
kubectl -n config-service port-forward svc/config-service 8081:8080
```

The application will then be available at:

```text
http://localhost:8081
```

---

# 14. Project Structure

```text
solution/rohan-tiwatne/
├── install.sh
├── Makefile
├── README.md
├── ...
└── ...
```

The solution contains the Go application, infrastructure configuration, Kubernetes manifests, deployment automation, testing, and supporting configuration required to run the service locally.

---

# 15. Operational Assumptions and Known Limitations

This implementation is intentionally designed for a **local Kubernetes environment** and focuses on demonstrating the infrastructure engineering requirements of the assignment.

The solution prioritizes:

* Reproducibility
* Simple local deployment
* Infrastructure automation
* Kubernetes-native configuration
* Persistent storage
* Health checks
* Operational validation

Production-scale concerns such as high availability, multi-node database clustering, external secret management, ingress/load balancing, and production-grade observability are outside the scope of this assignment.

---

# 16. Author

**Rohan Tiwatne**
