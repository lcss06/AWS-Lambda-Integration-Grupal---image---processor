// Lambda de subida: recibe una imagen por POST /upload (multipart/form-data) y la guarda en S3 dentro de uploads/
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const Busboy = require("busboy");
const { v4: uuidv4 } = require("uuid");

const s3 = new S3Client({});

const BUCKET = process.env.S3_BUCKET;
const PREFIX = process.env.UPLOAD_PREFIX || "uploads/";

// 4 MB: Lambda acepta 6 MB y API Gateway manda el archivo en base64 (+33%)
const MAX_BYTES = 4 * 1024 * 1024;

const ALLOWED = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
};

function respond(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}
function parseMultipart(event) {
  return new Promise((resolve, reject) => {
    // busboy necesita los headers en minuscula
    const headers = {};
    for (const [key, value] of Object.entries(event.headers || {})) {
      headers[key.toLowerCase()] = value;
    }

    let bb;
    try {
      bb = Busboy({ headers, limits: { files: 1, fileSize: MAX_BYTES } });
    } catch (err) {
      return reject(err);
    }

    let file = null;

    bb.on("file", (fieldName, stream, info) => {
      const chunks = [];
      let tooBig = false;
      stream.on("data", (chunk) => chunks.push(chunk));
      stream.on("limit", () => { tooBig = true; }); // paso los 4 MB
      stream.on("end", () => {
        file = {
          buffer: Buffer.concat(chunks),
          mimeType: info.mimeType,
          tooBig,
        };
      });
    });

    bb.on("error", reject);
    bb.on("close", () => resolve(file));

    const body = Buffer.from(event.body || "", event.isBase64Encoded ? "base64" : "utf8");
    bb.end(body);
  });
}

exports.handler = async (event) => {
  let file;
  try {
    file = await parseMultipart(event);
  } catch (err) {
    return respond(400, { error: "Se esperaba multipart/form-data" });
  }

  if (!file) {
    return respond(400, { error: "No se envio ningun archivo" });
  }
  if (file.tooBig) {
    return respond(413, { error: "La imagen supera los 4 MB" });
  }

  const ext = ALLOWED[file.mimeType];
  if (!ext) {
    return respond(415, { error: "Solo se permiten jpg, png, gif y webp" });
  }

  // nombre unico para que dos fotos iguales no se pisen
  const key = `${PREFIX}${uuidv4()}.${ext}`;

  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    Body: file.buffer,
    ContentType: file.mimeType,
  }));

  return respond(201, { message: "Imagen recibida", key });
};