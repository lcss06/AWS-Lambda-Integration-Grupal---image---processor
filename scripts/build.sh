#!/usr/bin/env bash
# Instala las dependencias de las Lambdas en version Linux x64 que es donde corren en AWS (aunque el build se haga en Windows o Mac)
# Uso: ./scripts/build.sh
set -euo pipefail

# carpeta raiz del repo, sin importar desde donde se ejecute el script
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for fn in upload crop; do
  echo "==> Instalando dependencias de $fn para Linux"
  cd "$ROOT/lambdas/$fn"
  rm -rf node_modules
  npm ci --omit=dev --os=linux --cpu=x64 --libc=glibc
done

echo "Listo. Ya se puede correr terraform apply."