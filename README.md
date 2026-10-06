# Image Processor en AWS con Terraform

Actividad grupal: despliegue de la arquitectura del diagrama en AWS usando Terraform, en tres entornos (dev, qa y prod).

El sistema recibe una imagen por `POST /upload`, la guarda en S3 y otra Lambda genera una version recortada en circulo de 40x40 px en PNG.

Flujo: API Gateway -> Lambda upload -> S3 (`uploads/`) -> SQS -> Lambda crop -> S3 (`processed/`). Si un mensaje falla 3 veces pasa a la DLQ y salta una alarma de CloudWatch que avisa por SNS.

## Integrantes

- Lucas: estructura del proyecto, entornos, API Gateway y README
- Jhonny: red (VPC, subredes, NAT, endpoints, security groups)
- Karina: S3, SQS, DLQ, notificaciones y alarma
- Renato: codigo de las Lambdas y su modulo

## Estructura

```
envs/
  dev/  qa/  prod/     cada entorno llama a los mismos modulos, solo cambia terraform.tfvars
modules/
  network/  storage/  observability/  lambdas/  api/
lambdas/
  upload/  crop/       codigo Node.js de las funciones
scripts/
```

Diferencias entre entornos:

| | dev | qa | prod |
| --- | --- | --- | --- |
| enable_nat_gateway | false | false | true |
| log_retention_days | 7 | 14 | 14 |

Todos los recursos llevan el prefijo `image-processor-<entorno>`, por eso se pueden tener los tres entornos en la misma cuenta.

## Decisiones

**Subida por multipart.** Usamos `multipart/form-data` y no JSON con base64. Es lo normal para subir archivos desde un navegador o con `curl -F`, el cliente no tiene que convertir la imagen y viaja tambien el nombre y el tipo del archivo. Con base64 la imagen pesa un 33% mas antes de salir.

Hay un limite a tener en cuenta: API Gateway acepta 10 MB pero la Lambda recibe maximo 6 MB, y el body le llega en base64. Por eso la Lambda acepta imagenes de hasta 4 MB y si es mas grande responde 413.

**NAT solo en prod.** Las Lambdas solo se comunican con S3 y SQS y lo hacen por los VPC Endpoints, no necesitan salir a internet. Como el NAT se cobra por hora aunque no se use, en dev y qa esta apagado (`enable_nat_gateway = false`) y en prod se deja para cumplir con el diagrama.

**Cosas del diagrama que tuvimos que ajustar:**

1. El endpoint de S3 es de tipo Gateway y no tiene security group, entonces la regla de salida de las Lambdas hacia S3 se hace con la prefix list del endpoint y no apuntando a un SG.
2. El trigger de SQS de la Lambda crop lo maneja el servicio de Lambda por fuera de la VPC, la funcion no lee la cola directamente. El endpoint de SQS se deja porque esta en el diagrama, pero los permisos de SQS en el rol de crop si son necesarios porque el trigger los usa.
3. La notificacion de S3 a SQS tiene que filtrar por `uploads/`. Si no, cada imagen que se guarda en `processed/` volveria a disparar el recorte y quedaria en bucle. Ademas la cola necesita una politica que deje a S3 mandarle mensajes.

Las replicas de AZ-b del diagrama no son otras funciones: es la misma Lambda configurada con las dos subredes privadas.

## Requisitos

- Terraform 1.6 o mayor
- AWS CLI v2
- Node.js 20
- Cuenta de AWS con un perfil configurado

## Configurar el perfil

```bash
aws configure --profile image-processor
aws sts get-caller-identity --profile image-processor
```

Region `us-east-1`. Si usan otro nombre de perfil hay que cambiar `aws_profile` en el `terraform.tfvars` del entorno.

## Desplegar

Primero instalar las dependencias de las Lambdas:

```bash
./scripts/build.sh
```

Cambiar `alarm_email` en `envs/<entorno>/terraform.tfvars` por un correo real y despues:

```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

Al final muestra el `account_id`, la `upload_url` y el nombre del bucket. Llega un correo de AWS para confirmar la suscripcion de la alarma.

## Probar

```bash
curl -F "file=@foto.jpg" "$(terraform output -raw upload_url)"

aws s3 ls s3://$(terraform output -raw bucket_name)/processed/ --profile image-processor
```

Los logs del recorte quedan en CloudWatch en `/aws/lambda/image-processor-<entorno>-crop`.

## Destruir

```bash
cd envs/<entorno>
terraform destroy
```

Puede tardar un rato en borrar la red porque Lambda demora en soltar las interfaces de red de la VPC. Al terminar revisar en la consola que no quede nada con el prefijo `image-processor`.
