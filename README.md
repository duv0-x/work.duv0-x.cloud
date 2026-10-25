# work.duv0-x.cloud

Instancia de [Gremio](https://github.com/duv0-x/gremio) de Duván Ballén: **`@root@duv0-x.cloud`**, servida en `https://work.duv0-x.cloud`. Corre en una Raspberry Pi detrás de un túnel de Cloudflare.

Este repo no tiene código de Gremio. Solo guarda **qué versión corre la instancia, su configuración y cómo se despliega**.

## Contenido

| Archivo | Qué es |
|---------|--------|
| `gremio.version` | Versión de Gremio que corre la instancia. La Pi la lee cada 5 minutos (`GREMIO_VERSION_URL`). |
| `config/gremio.env` | Host, `account-domain`, puerto y directorio de datos. Sin secretos. |
| `config/gremio-update.env` | Apunta el actualizador a `gremio.version` de este repo. |
| `pi/provision.sh` | Aprovisiona la instancia en la Pi (idempotente). |
| `pi/cloudflared-ingress.yml` | Regla del túnel para `work.duv0-x.cloud`. |
| `docs/migracion-desde-echo.md` | Runbook de la migración desde GoToSocial (`echo.duv0-x.cloud`). |

## Actualizar Gremio

1. Publicar una release en `duv0-x/gremio` (tag `vX.Y.Z`).
2. PR aquí cambiando `gremio.version`.
3. Al mergear, `gremio-update` lo instala en la Pi en ≤5 min (más la caché de `raw.githubusercontent.com`). Si `/readyz` no responde, hace rollback del binario y de la base.

## Secretos

Ninguno vive en este repo. Las credenciales SMTP del login (ADR-009 de Gremio) se guardan en Bitwarden y se cargan en la Pi, fuera del control de versiones.
