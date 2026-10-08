# topico SNS y alarma de la DLQ

resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}-alarms"
}

# AWS manda un correo para confirmar la suscripcion, hasta confirmarla no llegan avisos
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# si llega cualquier mensaje a la DLQ es porque crop fallo 3 veces con la misma imagen
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name        = "${var.name_prefix}-dlq-messages-alarm"
  alarm_description = "Hay mensajes en la DLQ ${var.dlq_name}"

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    QueueName = var.dlq_name
  }

  period              = 60
  evaluation_periods  = 1
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  # SQS no publica datos si la cola esta vacia, eso no es una alarma
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}
