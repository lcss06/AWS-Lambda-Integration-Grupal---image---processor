#!/usr/bin/env bash
# Sube una imagen al API desplegado y muestra la respuesta.
# Uso: ./scripts/test-upload.sh <entorno> <imagen>
# Ejemplo: ./scripts/test-upload.sh dev foto.jpg
set -euo pipefail

ENV="${1:?Falta el entorno: dev, qa o prod}"
IMG="${2:?Falta la ruta de la imagen}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# el tipo de archivo se manda explicito para que la Lambda lo acepte
EXT="$(echo "${IMG##*.}" | tr '[:upper:]' '[:lower:]')"
case "$EXT" in
  jpg|jpeg) TYPE="image/jpeg" ;;
  png)      TYPE="image/png" ;;
  gif)      TYPE="image/gif" ;;
  webp)     TYPE="image/webp" ;;
  *) echo "Formato no permitido: $EXT (usar jpg, png, gif o webp)"; exit 1 ;;
esac

# la URL la saca de los outputs de terraform del entorno elegido
URL="$(terraform -chdir="$ROOT/envs/$ENV" output -raw upload_url)"

echo "Subiendo $IMG a $URL"
curl -sS -F "file=@$IMG;type=$TYPE" "$URL"
echo