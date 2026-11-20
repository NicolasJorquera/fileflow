# Sitio de FileFlow

Sitio web del desarrollador para la ficha de Play, en Firebase Hosting (plan gratuito Spark), igual que Ludixa y TakeSync. Proyecto: `fileflow-app` (`.firebaserc`), sitio `fileflow-gonisoma` (`firebase.json`). `fileflow-app.web.app` ya era de otra persona: los nombres de sitio son globales.

| Ruta | Qué es |
|---|---|
| `https://fileflow-gonisoma.web.app/` | Portada con enlace a Play, política y contacto |
| `https://fileflow-gonisoma.web.app/app-ads.txt` | `google.com, pub-3038495459046159, DIRECT, f08c47fec0942fa0` |
| `/privacidad`, `/privacy` | Redirigen a la política publicada en GitHub Pages (`docs/privacy/`), que sigue siendo la única fuente |

## Publicar

```bash
# Ya creados: proyecto fileflow-app y sitio fileflow-gonisoma.
cd site
firebase deploy --only hosting
```

## Después de publicar

1. **Play Console** › Presencia en la tienda › Detalles de la app › Sitio web: `https://fileflow-gonisoma.web.app`.
2. **AdMob** › Apps › FileFlow: vincular con la ficha de Play y verificar `app-ads.txt` (Google tarda hasta 24 h en rastrearlo).
