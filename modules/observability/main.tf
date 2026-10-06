# Parte 3 — Monitoreo (Karina)
#
# Qué hay que construir (ver diagrama, bloque "Observability"):
#  [ ] aws_sns_topic "${var.name_prefix}-alarms"
#  [ ] aws_sns_topic_subscription protocolo "email" a var.alarm_email
#      (AWS manda un correo de confirmación; queda "pending" hasta aceptarlo)
#  [ ] aws_cloudwatch_metric_alarm "${var.name_prefix}-dlq-messages-alarm":
#        namespace AWS/SQS, métrica ApproximateNumberOfMessagesVisible,
#        dimensión QueueName = var.dlq_name, period 60, statistic Maximum,
#        comparison GreaterThanThreshold, threshold 0, alarm_actions = [tópico SNS]
#
# Los log groups de las Lambdas y de la API NO van aquí: los crea cada módulo dueño.
