output "namespace" {
  value = kubernetes_namespace.config_service.metadata[0].name
}

output "postgres_service" {
  value = kubernetes_service.postgres.metadata[0].name
}
