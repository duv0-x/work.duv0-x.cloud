# CLAUDE.md — work.duv0-x.cloud

Repo de la **instancia** de Gremio de Duván (`@root@duv0-x.cloud` en `https://work.duv0-x.cloud`), no del producto. El código de Gremio vive en `/Users/lx-duv0-x/Documents/Repositories/gremio`. Español, con términos técnicos en inglés.

## Reglas

- **Esto es producción.** Cualquier escritura en la Pi `alfred`, en Cloudflare o en el apex `duv0-x.cloud` requiere autorización explícita, paso a paso, y se reporta el resultado antes de seguir.
- **Nunca commitear secretos** (SMTP, tokens). Van en Bitwarden y se cargan en la Pi.
- `GREMIO_HOST` y `GREMIO_ACCOUNT_DOMAIN` son permanentes: Gremio se niega a arrancar si cambian.
- Subir de versión = PR que cambia `gremio.version`; el merge lo aplica en la Pi.
- La Pi: `alfred@192.168.1.15`, Debian 13 arm64. Su llave SSH ED25519 es `SHA256:vtZ1eNuK2kbQLhIHnJ/dkJcoJTiOzHZHsRkfEh17jBo`. Si cambia, parar y preguntar.

## Contexto

- Runbook de la migración: `docs/migracion-desde-echo.md`.
- Decisiones: ADRs en el repo `gremio` (`docs/adr/`) y la KB (`/Users/lx-duv0-x/Documents/ia-kb/drafts/plataforma-perfiles/README.md`).
