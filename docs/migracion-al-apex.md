# Migración al apex duv0-x.cloud (work.duv0-x.cloud#39)

La instancia pasa de `https://work.duv0-x.cloud` a `https://duv0-x.cloud`, con una **identidad nueva**: el actor pasa a ser `https://duv0-x.cloud/users/root` y el handle sigue siendo `@root@duv0-x.cloud`. Gremio no permite cambiar `--host` sobre la misma base, así que se crea una base nueva y la vieja queda de respaldo. El único seguidor tiene que volver a seguir.

Plan completo y decisiones: `ia-kb/plans/2026-11-04-work.duv0-x.cloud-39-migracion-al-apex.md`.

## 0. Requisitos

- gremio ≥ v0.17.0 en la Pi (`admin media`), fijado en `gremio.version`.
- Las capturas de proyectos en la Mac: `projects.duv0-x.cloud/public/images/{papiro,mockingbird,gremio}.jpg`. Su nombre en `/media` sale de su hash, así que no cambia:

  | Proyecto | URL nueva |
  |----------|-----------|
  | gremio | `https://duv0-x.cloud/media/media-d881dd5ca802ee08.jpg` |
  | mockingbird | `https://duv0-x.cloud/media/media-f300e2557e1b2c3c.jpg` |
  | papiro | `https://duv0-x.cloud/media/media-b58335390636cd68.jpg` |

- El perfil (`ia-kb/drafts/plataforma-perfiles/perfil-duvan.es.json`) con esas URLs en `projects[].image` y `https://duv0-x.cloud` en la `url` del proyecto gremio. Se cambia **en el corte**, no antes: importado en la instancia vieja, rompería las imágenes.

## 1. Respaldo (Pi)

```bash
F=$(date +%Y%m%d)
sudo -u gremio GREMIO_DATA_DIR=/gremio/data /gremio/gremio backup
sudo -u gremio GREMIO_DATA_DIR=/gremio/data /gremio/gremio admin export > /tmp/perfil-work.json
```

## 2. Apex libre (Cloudflare)

Quitar los custom domains `duv0-x.cloud` y `www.duv0-x.cloud` del worker `duv0-x-cloud` (la botonera), en el dashboard o borrando sus `routes` y haciendo deploy. Desde ese momento el apex no responde hasta el paso 4.

## 3. Instancia nueva (Pi)

```bash
sudo systemctl stop gremio
sudo mv /gremio/data /gremio/data-work-$F
sudo install -d -m 0700 -o gremio -g gremio /gremio/data
sudo cp /gremio/gremio.env /gremio/gremio.env.bak-$F
sudo install -m 0600 -o root -g root config/gremio.env /gremio/gremio.env   # copiado antes por scp
G="sudo -u gremio GREMIO_DATA_DIR=/gremio/data /gremio/gremio"
$G admin init --username root --email duvan.ballen@gmail.com
sudo systemctl start gremio            # el primer serve fija el host https://duv0-x.cloud
$G admin media /tmp/gremio.jpg /tmp/mockingbird.jpg /tmp/papiro.jpg   # tienen que dar las URLs de la tabla
echo s | $G admin import /tmp/perfil.json                            # el perfil con las URLs nuevas
$G admin cv-pdf /gremio/data-work-$F/cv.pdf
$G admin profile --avatar /gremio/data-work-$F/media/avatar-*.jpg  # si el perfil viejo tenía avatar
```

`admin init` crea un par de llaves nuevo, como corresponde a la identidad nueva.

## 4. Túnel y DNS

- En `/etc/cloudflared/config.yml` de la Pi, la regla de `pi/cloudflared-ingress.yml` en lugar de la de `work.`; luego `sudo systemctl restart cloudflared`.
- Desde la Mac, con `cert.pem`: `cloudflared tunnel route dns alfred duv0-x.cloud`.

## 5. Redirecciones (dashboard → Rules → Redirect Rules)

- `work.duv0-x.cloud`: **301** a `https://duv0-x.cloud${http.request.uri.path}`, conservando la query. Su CNAME al túnel queda proxied.
- `www.duv0-x.cloud`: igual. Si se quedó sin registro al quitar el custom domain, `AAAA www 100::` proxied.

## 6. Verificación

```bash
curl -s https://duv0-x.cloud/readyz
curl -s "https://duv0-x.cloud/.well-known/webfinger?resource=acct:root@duv0-x.cloud"   # 200, self = https://duv0-x.cloud/users/root
curl -sI https://work.duv0-x.cloud/@root | grep -i location                          # https://duv0-x.cloud/@root
curl -sI https://www.duv0-x.cloud/ | grep -i location
```

- `https://duv0-x.cloud/@root` con el perfil, el CV, el avatar y las capturas de la pestaña Proyectos.
- Login del panel en `https://duv0-x.cloud/login`.
- Buscar `@root@duv0-x.cloud` desde Mastodon y seguirlo. Mastodon puede tener cacheado el actor viejo con ese acct.

## Rollback (antes de la limpieza)

```bash
sudo systemctl stop gremio
sudo mv /gremio/data /gremio/data-apex-fallido && sudo mv /gremio/data-work-$F /gremio/data
sudo cp /gremio/gremio.env.bak-$F /gremio/gremio.env && sudo systemctl start gremio
```

Volver a poner la regla de `work.` en el túnel, quitar la redirección de `work.` y devolverle los custom domains al worker de la botonera.
