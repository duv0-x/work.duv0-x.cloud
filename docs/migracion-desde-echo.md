# Migración: de GoToSocial (echo.duv0-x.cloud) a Gremio (work.duv0-x.cloud)

> **Ejecutada el 2026-10-24.** Pasos 1–7 completos; del paso 8 queda solo el botón "Trabajo" (cuando el perfil tenga web). El CNAME `echo.` se borró desde el dashboard (el token del MCP de Cloudflare no tiene `dns.write`). El respaldo de echo está en la Mac del dueño (`~/Backups/echo.duv0-x.cloud/`).

`@root@duv0-x.cloud` deja de ser la cuenta de GoToSocial en `echo.duv0-x.cloud` y pasa a ser la instancia de Gremio en `work.duv0-x.cloud`, en la misma Pi `alfred`. **No se migran seguidores ni seguidos**: es una decisión explícita.

Cada paso que toca producción se ejecuta **solo con autorización explícita**, y se reporta el resultado antes de seguir.

## Estado de partida (2026-10-24)

- Pi `alfred` (`alfred@192.168.1.15`, Debian 13, arm64, 1 GB):
  - GoToSocial en `/gotosocial`, usuario `gotosocial`, escuchando en `127.0.0.1:8080`;
  - `gotosocial-update.timer` activo.
- `cloudflared` local (`/etc/cloudflared/config.yml`, túnel `alfred`), con una sola regla: `echo.duv0-x.cloud → localhost:8080`.
- El Worker del apex (`duv0-x/duv0-x.cloud`) redirige `/.well-known/{webfinger,host-meta,nodeinfo}` a `echo.duv0-x.cloud` y publica `<link rel="me" href="https://echo.duv0-x.cloud/@root">`.

## Pasos

### 1. Respaldo de echo

- `config.yaml` y `storage/sqlite.db` (con `-wal`/`-shm` si existen), copiados a la Mac con el servicio detenido unos segundos para que la base quede consistente.
- La media (`storage/`, ~6 GB, casi toda caché remota) es opcional.
- **Rollback**: ninguno; solo lee.

### 2. Instalar Gremio en la Pi (sin exponerlo)

- Copiar este repo a la Pi y correr `sudo ./pi/provision.sh`. Crea el usuario `gremio` y `/gremio`, instala `gremio.version`, crea al dueño `root` y arranca `gremio` en `127.0.0.1:8081` junto con `gremio-update.timer`.
- Verificar: `curl -s 127.0.0.1:8081/readyz` y `systemctl status gremio`.
- **Rollback**: `systemctl disable --now gremio gremio-update.timer` y borrar `/gremio`, las unidades y el usuario. GoToSocial no se entera.

### 3. Exponer work.duv0-x.cloud

- Agregar la regla de `pi/cloudflared-ingress.yml` a `/etc/cloudflared/config.yml` (antes de `http_status:404`) y `systemctl restart cloudflared`.
- Desde la Mac (con `cert.pem`): `cloudflared tunnel route dns alfred work.duv0-x.cloud`.
- Verificar: `https://work.duv0-x.cloud/readyz` y el Actor en `https://work.duv0-x.cloud/users/root`.
- **Rollback**: quitar la regla y reiniciar `cloudflared`. `echo` sigue funcionando.

### 4. Borrar la cuenta de GoToSocial (lo hace el dueño)

- En la web de `echo`: Ajustes → Cuenta → Borrar. GoToSocial federa un `Delete` a los servidores de los seguidores.
- Dejar `echo` encendido unos minutos para que salgan esas entregas.
- **Rollback**: no hay. La cuenta borrada no se recupera, salvo restaurando el respaldo del paso 1.

### 5. Apagar echo

- `systemctl disable --now gotosocial gotosocial-update.timer`.
- Quitar la regla `echo.duv0-x.cloud` de `/etc/cloudflared/config.yml` y reiniciar `cloudflared`.
- El CNAME `echo.duv0-x.cloud` se borra en Cloudflare (dashboard o API).
- `/gotosocial` se conserva en disco hasta confirmar que todo funciona.
- **Rollback**: `systemctl enable --now gotosocial` y volver a poner la regla.

### 6. Apuntar el apex a Gremio

- PR en `duv0-x/duv0-x.cloud`: las redirecciones de `/.well-known/*` pasan a `https://work.duv0-x.cloud` y se quita el `rel="me"` a `echo`. El merge despliega a producción, así que lo corre el dueño.
- Verificar: `curl -sI 'https://duv0-x.cloud/.well-known/webfinger?resource=acct:root@duv0-x.cloud'` → `301` a `work.duv0-x.cloud`.
- **Rollback**: revertir el PR.

### 7. Probar desde Mastodon

- Desde `@duv0_x@mastodon.social`: buscar `@root@duv0-x.cloud`, seguirlo y publicar un `Note` con `sudo -u gremio GREMIO_DATA_DIR=/gremio/data /gremio/gremio admin note --text "…"`.
- mastodon.social puede mostrar un tiempo el perfil viejo de `echo` que tiene en caché.

### 8. Limpieza

- Archivar el repo `duv0-x/echo.duv0-x.cloud` en GitHub.
- Borrar `/gotosocial`, el usuario `gotosocial`, `/usr/local/bin/gotosocial-update` y sus unidades cuando ya no haga falta el respaldo en disco.
- Activar el botón "Trabajo" de la botonera cuando el perfil tenga web.
