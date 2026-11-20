# Sitio de FileFlow

Sitio web del desarrollador para la ficha de Play, en Firebase Hosting (plan gratuito Spark), igual que Ludixa y TakeSync. Proyecto: `fileflow-app` (`.firebaserc`).

| Ruta | Qué es |
|---|---|
| `https://fileflow-app.web.app/` | Portada con enlace a Play, política y contacto |
| `https://fileflow-app.web.app/app-ads.txt` | `google.com, pub-3038495459046159, DIRECT, f08c47fec0942fa0` |
| `/privacidad`, `/privacy` | Redirigen a la política publicada en GitHub Pages (`docs/privacy/`), que sigue siendo la única fuente |

## Publicar

```bash
firebase projects:create fileflow-app --display-name "FileFlow"   # solo la primera vez
cd site
firebase deploy --only hosting
```

## Después de publicar

1. **Play Console** › Presencia en la tienda › Detalles de la app › Sitio web: `https://fileflow-app.web.app`.
2. **AdMob** › Apps › FileFlow: vincular con la ficha de Play y verificar `app-ads.txt` (Google tarda hasta 24 h en rastrearlo).
