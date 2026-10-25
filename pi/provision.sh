#!/bin/bash
# Aprovisiona la instancia de Gremio de work.duv0-x.cloud en la Pi `alfred`. Idempotente.
# Correr como root desde una copia de este repo en la Pi:  sudo ./pi/provision.sh
# Instala la versión de gremio.version con las plantillas deploy/ de esa misma release.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
REPO=duv0-x/gremio
DIR=/gremio

version=$(tr -d '[:space:]' < "$here/gremio.version")
if ! [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "gremio.version inválido: '$version'" >&2
  exit 1
fi
case "$(uname -m)" in
  aarch64|arm64) arch=arm64 ;;
  x86_64|amd64) arch=amd64 ;;
  *) echo "arquitectura no soportada: $(uname -m)" >&2; exit 1 ;;
esac

echo "== usuario y directorios"
id gremio >/dev/null 2>&1 || useradd --system --home "$DIR" --shell /usr/sbin/nologin gremio
install -d -m 0755 -o root -g root "$DIR"
install -d -m 0700 -o gremio -g gremio "$DIR/data"
install -m 0600 -o root -g root "$here/config/gremio.env" "$DIR/gremio.env"
install -m 0600 -o root -g root "$here/config/gremio-update.env" "$DIR/gremio-update.env"

echo "== release $version"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
file="gremio_${version#v}_linux_${arch}.tar.gz"
curl -fsSL -o "$tmp/$file" "https://github.com/$REPO/releases/download/$version/$file"
curl -fsSL -o "$tmp/checksums.txt" "https://github.com/$REPO/releases/download/$version/checksums.txt"
(cd "$tmp" && sha256sum -c --ignore-missing checksums.txt)
mkdir "$tmp/new"
tar -xzf "$tmp/$file" -C "$tmp/new"

install -m 0755 -o root -g root "$tmp/new/deploy/gremio-update" /usr/local/bin/gremio-update
install -m 0644 -o root -g root "$tmp/new/deploy/gremio.service" "$tmp/new/deploy/gremio-update.service" \
  "$tmp/new/deploy/gremio-update.timer" /etc/systemd/system/
systemctl daemon-reload

# Primera instalación: el binario y el dueño van antes de arrancar el servicio, porque `serve` falla sin dueño.
# Después, las actualizaciones las hace gremio-update.timer.
if [ ! -f "$DIR/gremio" ]; then
  install -m 0755 -o root -g root "$tmp/new/gremio" "$DIR/gremio"
  echo "$version" > "$DIR/.release"
fi
if [ ! -f "$DIR/data/gremio.db" ]; then
  echo "== dueño @root"
  sudo -u gremio GREMIO_DATA_DIR="$DIR/data" "$DIR/gremio" admin init --username root
fi

echo "== servicios"
systemctl enable --now gremio.service gremio-update.timer
for _ in $(seq 1 30); do
  if curl -sf -o /dev/null http://127.0.0.1:8081/readyz; then
    echo "gremio $(cat "$DIR/.release") listo en 127.0.0.1:8081"
    exit 0
  fi
  sleep 2
done
echo "gremio no respondió /readyz; revisa: journalctl -u gremio" >&2
exit 1
