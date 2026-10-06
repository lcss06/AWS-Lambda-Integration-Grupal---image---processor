# CONTRATO. Valores temporales para que "terraform validate" pase.

output "sns_topic_arn" {
  value = "" # TODO(Karina): aws_sns_topic.alarms.arn
}
