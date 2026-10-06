# Los nombres se usan en envs/*/main.tf, no cambiarlos.
# Valores vacios mientras se arma el modulo.

output "sns_topic_arn" {
  value = "" # TODO: aws_sns_topic.alarms.arn
}
