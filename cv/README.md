# CV

Fuente del PDF que publica la instancia en `https://duv0-x.cloud/@root/cv.pdf` (botón "Descargar CV"). Es la versión pública: sin teléfono y con el alias `work@duv0-x.cloud` (Cloudflare Email Routing → Gmail) en lugar del correo personal. Viene de `me.duv0-x.cloud`, archivado desde 2026-11-04.

| Archivo | Qué es |
|---------|--------|
| `cv-public.yaml` | Fuente en formato [RenderCV](https://rendercv.com), tema `sb2nov` |
| `cv.pdf` | El PDF generado, el mismo que sirve la instancia |

## Regenerar y publicar

```bash
cd cv
uvx --from 'rendercv[full]' rendercv render cv-public.yaml     # deja el PDF en rendercv_output/
cp "rendercv_output/Duván_Ballén_Rodríguez_CV.pdf" cv.pdf
scp cv.pdf alfred@<pi>:/tmp/cv.pdf
ssh alfred@<pi> 'sudo chown gremio /tmp/cv.pdf && sudo -u gremio GREMIO_DATA_DIR=/gremio/data /gremio/gremio admin cv-pdf /tmp/cv.pdf && rm /tmp/cv.pdf'
```

`rendercv_output/` no se versiona.
