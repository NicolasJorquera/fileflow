# Data safety (Play Console)

Respuestas para el formulario de seguridad de los datos. No hubo revisión de un abogado: se basan en lo que hace la app y en la guía de Google para el SDK de anuncios de AdMob.

## ¿La app recoge o comparte datos de usuario?

Sí, solo a través del SDK de Google Mobile Ads (AdMob). FileFlow no tiene servidores ni analítica propia.

| Tipo de dato (Play) | Recogido | Compartido | Opcional | Motivo |
|---|---|---|---|---|
| Ubicación aproximada (por la IP) | Sí | Sí, Google | No | Publicidad, prevención de fraude |
| Identificadores del dispositivo u otros (ID de publicidad) | Sí | Sí, Google | No | Publicidad, analítica de anuncios, prevención de fraude |
| Actividad en la app: interacciones (con los anuncios) | Sí | Sí, Google | No | Publicidad, analítica de anuncios |
| Información y rendimiento de la app: diagnóstico | Sí | Sí, Google | No | Publicidad, prevención de fraude |
| Archivos y documentos, fotos | No: se procesan en el teléfono y no salen de él | No | — | — |

- Los datos se cifran en tránsito: sí (el SDK de AdMob usa HTTPS).
- Las personas pueden pedir que se borren los datos: los datos de la app se borran desde Recientes o desinstalando; los de anuncios, con Google (ID de publicidad restablecible).
- La app no está dirigida a niños.
- Política de privacidad: https://nicolasjorquera.github.io/fileflow/privacy/

## Declaración de ID de publicidad

Sí, la app usa el ID de publicidad, para anuncios (permiso `AD_ID` añadido por el SDK de AdMob).
