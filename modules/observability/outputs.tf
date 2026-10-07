# Los nombres se usan en envs/*/main.tf, no cambiarlos.

output "sns_topic_arn" {
  value = aws_sns_topic.alarms.arn
}
