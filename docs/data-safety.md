# Data safety (Play Console)

Respuestas para el formulario de seguridad de los datos. No hubo revisión de un abogado: se basan en lo que hace la app y en la guía de Google para el SDK de anuncios de AdMob.

## ¿La app recoge o comparte datos de usuario?

Sí, solo a través del SDK de Google Mobile Ads (AdMob). FileFlow no tiene servidores ni analítica propia.

La compra única «Sin anuncios» (`fileflow_remove_ads`, Google Play Billing) no agrega datos que declarar: el pago lo procesa Google Play, la app no recibe datos de pago y solo guarda en el teléfono si la compra existe, sin enviarlo a ningún servidor. Lo que Google Play recoge para cobrar lo trata Google, no FileFlow. Pendiente: confirmar en la ayuda de Play Console, al llenar el formulario, que los datos de Play Billing no hay que declararlos (no se verificó).

| Tipo de dato (Play) | Recogido | Compartido | Opcional | Motivo |
|---|---|---|---|---|
| Ubicación aproximada (por la IP) | Sí | Sí, Google | No | Publicidad, prevención de fraude |
| Identificadores del dispositivo u otros (ID de publicidad) | Sí | Sí, Google | No | Publicidad, analítica de anuncios, prevención de fraude |
| Actividad en la app: interacciones (con los anuncios) | Sí | Sí, Google | No | Publicidad, analítica de anuncios |
| Información y rendimiento de la app: diagnóstico | Sí | Sí, Google | No | Publicidad, prevención de fraude |
| Archivos y documentos, fotos | No: se procesan en el teléfono y no salen de él | No | — | — |
| Información financiera: historial de compras | No: la app solo guarda en el teléfono si existe la compra «Sin anuncios» | No | — | — |

- Los datos se cifran en tránsito: sí (el SDK de AdMob usa HTTPS).
- Las personas pueden pedir que se borren los datos: los datos de la app se borran desde Recientes o desinstalando; los de anuncios, con Google (ID de publicidad restablecible).
- Con la compra «Sin anuncios» la app no pide ni muestra anuncios; desde el siguiente inicio tampoco inicia AdMob ni UMP, así que deja de enviarles datos.
- La app no está dirigida a niños.
- Política de privacidad: https://nicolasjorquera.github.io/fileflow/privacy/

## Declaración de ID de publicidad

Sí, la app usa el ID de publicidad, para anuncios (permiso `AD_ID` añadido por el SDK de AdMob).
