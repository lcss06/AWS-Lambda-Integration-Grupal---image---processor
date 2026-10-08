const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");
const path = require("path");

const s3 = new S3Client({});

// estos valores los pone Terraform como variables de entorno
const BUCKET = process.env.S3_BUCKET;
const PROCESSED_PREFIX = process.env.PROCESSED_PREFIX || "processed/";

const SIZE = 40;

// mascara: un circulo blanco del mismo tamaño que la imagen final
const CIRCLE_MASK = Buffer.from(
  `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}">
     <circle cx="${SIZE / 2}" cy="${SIZE / 2}" r="${SIZE / 2}" fill="#fff"/>
   </svg>`
);

// recibe la imagen original y devuelve el PNG circular de 40x40
async function cropToCircle(input) {
  return sharp(input)
    .resize(SIZE, SIZE, { fit: "cover" })
    .composite([{ input: CIRCLE_MASK, blend: "dest-in" }])
    .png()
    .toBuffer();
}

// procesa una imagen: la baja de S3, la recorta y sube el resultado
async function processRecord(s3Record) {
  const key = decodeURIComponent(s3Record.s3.object.key.replace(/\+/g, " "));

  const original = await s3.send(new GetObjectCommand({ Bucket: BUCKET, Key: key }));
  const input = Buffer.from(await original.Body.transformToByteArray());

  const output = await cropToCircle(input);

  const name = path.basename(key, path.extname(key));
  const outKey = `${PROCESSED_PREFIX}${name}_circular.png`;

  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: outKey,
    Body: output,
    ContentType: "image/png",
  }));

  console.log(`Recortada ${key} -> ${outKey}`);
}

exports.handler = async (event) => {
  // aqui se anotan los mensajes que fallaron, para que SQS los reintente
  const batchItemFailures = [];

  // SQS manda hasta 5 mensajes juntos (batch size 5)
  for (const message of event.Records) {
    try {
      const body = JSON.parse(message.body);

      // al crear la notificacion, S3 manda un mensaje de prueba: se ignora
      if (body.Event === "s3:TestEvent") {
        console.log("Ignorando s3:TestEvent");
        continue;
      }

      for (const s3Record of body.Records || []) {
        await processRecord(s3Record);
      }
    } catch (err) {
      console.error(`Fallo el mensaje ${message.messageId}:`, err);
      batchItemFailures.push({ itemIdentifier: message.messageId });
    }
  }

  return { batchItemFailures };
};
exports.cropToCircle = cropToCircle;