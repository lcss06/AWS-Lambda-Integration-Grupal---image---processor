# Image Processor — AWS con Terraform

Arquitectura serverless que recibe una imagen por HTTP, la guarda en S3 y genera automáticamente una versión recortada en círculo de 40x40 px (PNG con fondo transparente). Se despliega con Terraform en tres entornos: **DEV**, **QA** y **PROD**.

## Flujo

```
Cliente --POST /upload--> API Gateway (HTTP API) --> Lambda upload --> S3 uploads/
                                                                          |
                                                    S3 Event Notification (ObjectCreated)
                                                                          v
                         S3 processed/ <-- Lambda crop <-- trigger SQS <-- Cola SQS --(3 fallos)--> DLQ --> Alarma CloudWatch --> SNS
```

Las Lambdas corren en subredes privadas de una VPC y llegan a S3 y SQS por VPC Endpoints, sin pasar por internet.

## Equipo

| Integrante | Parte | Carpetas |
| --- | --- | --- |
| Lucas | 1 · Base del proyecto, entornos, API Gateway, README | `envs/`, `modules/api/` |
| Jhonny | 2 · Red: VPC, subredes, NAT, endpoints, security groups | `modules/network/` |
| Karina | 3 · S3, SQS, DLQ, notificación, SNS y alarma | `modules/storage/`, `modules/observability/` |
| Renato | 4 · Código y despliegue de las Lambdas | `lambdas/`, `modules/lambdas/`, `scripts/` |

## Estructura

```
.
├── envs/
│   ├── dev/     # main.tf igual en los 3 entornos; solo cambia terraform.tfvars
│   ├── qa/
│   └── prod/
├── modules/
│   ├── network/
│   ├── storage/
│   ├── observability/
│   ├── lambdas/
│   └── api/
├── lambdas/
│   ├── upload/  # Node.js 20: recibe multipart y guarda en uploads/
│   └── crop/    # Node.js 20 + sharp: recorta a círculo 40x40 y guarda en processed/
└── scripts/
```

### Diferencias entre entornos

| Variable | DEV | QA | PROD |
| --- | --- | --- | --- |
| `environment` | `dev` | `qa` | `prod` |
| `enable_nat_gateway` | `false` | `false` | `true` |
| `log_retention_days` | 7 | 14 | 14 |

Todos los recursos se nombran `image-processor-<entorno>-...`, así los tres entornos pueden convivir en la misma cuenta.

### Contrato entre módulos

`envs/*/main.tf` conecta los módulos usando estos outputs. Si alguien necesita cambiar un nombre, lo avisa al grupo antes.

| Módulo | Outputs |
| --- | --- |
| `storage` | `bucket_name`, `bucket_arn`, `uploads_prefix`, `processed_prefix`, `queue_arn`, `dlq_name` |
| `network` | `vpc_id`, `private_subnet_ids`, `sg_upload_lambda_id`, `sg_crop_lambda_id` |
| `observability` | `sns_topic_arn` |
| `lambdas` | `upload_function_name`, `upload_invoke_arn`, `crop_function_name` |
| `api` | `api_id`, `api_endpoint`, `upload_url` |

## Decisiones de diseño

### Subida por multipart/form-data

Elegimos `multipart/form-data` en lugar de JSON con base64:

- Es el formato estándar de navegadores y de `curl -F`; el cliente no tiene que codificar la imagen.
- El nombre y el tipo de archivo viajan en el mismo request.
- base64 agrega un 33% al tamaño antes de salir del cliente.

**Límite real:** API Gateway acepta 10 MB, pero una Lambda invocada de forma síncrona recibe como máximo 6 MB, y API Gateway le entrega el cuerpo binario en base64. Por eso la Lambda upload acepta imágenes de hasta **4 MB** y responde `413` si se pasa. Para 10 MB reales habría que usar URLs prefirmadas de S3.

### NAT Gateways solo en PROD

Las Lambdas solo hablan con S3 y SQS, y lo hacen por VPC Endpoints, así que no necesitan salida a internet. Los NAT Gateways se cobran por hora aunque no se usen, por eso `enable_nat_gateway` es `true` solo en PROD (para respetar el diagrama) y `false` en DEV y QA.

### Configuraciones del diagrama que corregimos

1. **Security group hacia el endpoint de S3.** El endpoint de S3 es de tipo Gateway y no tiene security group. La regla de salida de las Lambdas usa la prefix list del endpoint (`prefix_list_ids`), no un SG.
2. **Endpoint de SQS y la Lambda crop.** El trigger de SQS (event source mapping) lo ejecuta el servicio Lambda fuera de la VPC; la función no lee la cola por sí misma. El endpoint se mantiene porque está en el diagrama, pero los permisos `sqs:ReceiveMessage`, `DeleteMessage`, `GetQueueAttributes` y `ChangeMessageVisibility` del rol sí son obligatorios porque el trigger los usa.
3. **Notificación de S3 a SQS.** Filtra el prefijo `uploads/`; sin el filtro, cada PNG escrito en `processed/` volvería a disparar el recorte en bucle. La cola tiene una política que permite a `s3.amazonaws.com` enviarle mensajes solo desde nuestro bucket.

Otros detalles: las "réplicas AZ-b" del diagrama son la misma función configurada con las dos subredes privadas; el bucket usa `force_destroy` para que `terraform destroy` lo pueda borrar aunque tenga versionado; la visibilidad de la cola (360 s) es 6 veces el timeout de la Lambda crop (60 s).

## Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.6 o superior
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Node.js 20 y npm
- Una cuenta de AWS con un perfil configurado (ver abajo)

## 1. Configurar el perfil de AWS

Se usa autenticación por perfil, sin access keys en el código:

```bash
aws configure --profile image-processor
# Region: us-east-1, Output: json

aws sts get-caller-identity --profile image-processor
```

Si usas otro nombre de perfil, cámbialo en `aws_profile` dentro de `envs/<entorno>/terraform.tfvars`.

## 2. Preparar las Lambdas

```bash
./scripts/build.sh
```

Instala las dependencias de `lambdas/upload` y `lambdas/crop`. `sharp` se instala para Linux x64 (el sistema de Lambda) aunque estés en Windows o Mac.

## 3. Desplegar

Antes del primer despliegue, cambia `alarm_email` en `terraform.tfvars` por un correo real.

```bash
cd envs/dev        # o envs/qa, envs/prod
terraform init
terraform plan
terraform apply
```

Al terminar, Terraform muestra `account_id`, `upload_url` y `bucket_name`. AWS envía un correo para confirmar la suscripción a la alarma.

## 4. Probar el recorte

```bash
UPLOAD_URL=$(terraform output -raw upload_url)
BUCKET=$(terraform output -raw bucket_name)

curl -F "file=@foto.jpg" "$UPLOAD_URL"

aws s3 ls "s3://$BUCKET/uploads/"   --profile image-processor
aws s3 ls "s3://$BUCKET/processed/" --profile image-processor
aws s3 cp "s3://$BUCKET/processed/<nombre>_circular.png" . --profile image-processor
```

Los logs del recorte están en CloudWatch, en `/aws/lambda/image-processor-<entorno>-crop`.

## 5. Destruir

```bash
cd envs/<entorno>
terraform destroy
```

Las interfaces de red que Lambda crea en la VPC pueden tardar varios minutos en liberarse, así que el borrado de las subredes y security groups puede demorar. Al final, revisa en la consola que no queden recursos `image-processor-*`.

## Cómo trabajamos

- `main` está protegida: todo entra por Pull Request.
- Una rama por parte: `feat/base`, `feat/network`, `feat/storage`, `feat/lambdas`.
- Cada PR recibe al menos un comentario de cada integrante antes del merge.
- Antes de abrir un PR: `terraform fmt -recursive` y `terraform validate` en `envs/dev`.
