# FileFlow

App de herramientas PDF que procesa todo en el teléfono: escanear, unir, reducir tamaño, organizar páginas y convertir, sin cuenta y sin subir archivos. Android primero; iOS después del gate E.

Documentos del proyecto: PRD v0.2, especificación UX v1.0, arquitectura v1.0 y plan por hitos (enlaces en el informe de discovery).

## Requisitos

- [FVM](https://fvm.app) con Flutter 3.47.9 (fijado en `.fvmrc`): `fvm install`.
- Este es un repo personal: resolver paquetes contra pub.dev, no contra un mirror de trabajo.

```bash
export PUB_HOSTED_URL=https://pub.dev
fvm flutter pub get
```

## Ejecutar

```bash
fvm flutter run --flavor dev -t lib/main_dev.dart     # anuncios de prueba (desde H9), se instala junto a prod
fvm flutter run --flavor prod -t lib/main.dart
```

## Verificaciones (las mismas que CI)

```bash
fvm dart format --output=none --set-exit-if-changed lib test tool
fvm flutter analyze
fvm dart run tool/check_imports.dart                  # reglas de capas y de red
fvm flutter test                                      # unitarias, widgets, golden y accesibilidad
fvm flutter test --update-goldens                     # regenerar golden tras un cambio visual aprobado

# Motor PDF (Dart puro, con el PDFium de escritorio), desde packages/pdf_engine:
fvm dart run tool/make_fixtures.dart                  # PDFs de prueba sintéticos (~1 min)
fvm dart test                                         # operaciones, robustez, compresión, estabilidad
fvm dart run tool/fuzz.dart 200                       # lo mismo que corre cada noche en CI

# Plugin Kotlin, desde android/:
./gradlew :platform_files:testDebugUnitTest
```

## Estructura

- `lib/core/domain`: Dart puro (`Result`, `AppFailure`, puertos de archivos, códec y ajustes). No importa Flutter ni `dart:io`.
- `lib/core/jobs`: `JobRunner` (una operación a la vez, progreso, cancelación). Dart puro.
- `lib/design_system`: tokens claro y oscuro del sistema de diseño aprobado, y el tema.
- `lib/l10n`: textos en ARB. `app_es.arb` es la plantilla; `app_pt.arb` tiene el contenido de Brasil; `app_es_ES.arb` solo lo que cambia en España.
- `lib/data`: adaptadores. `files/` implementa `FileGateway`, `ImageCodec` y `JobWorkspace` sobre el plugin `platform_files`.
- `lib/app/bootstrap.dart`: único lugar que construye adaptadores (raíz de composición).
- `lib/features/dev_tools`: pantalla de diagnóstico, solo en el flavor dev (Ajustes › Diagnóstico).
- `packages/pdf_engine`: motor PDF en Dart puro sobre PDFium (pdfrx_engine + pdfium_dart). Tareas cortas que no lanzan excepciones; resultado como dato.
- `packages/platform_files`: plugin Kotlin propio. Selector de documentos y Photo Picker, copias por streaming, guardar en carpeta, compartir con FileProvider limitado a `files/results/`, recepción de «Compartir» y JPEG nativo.
- `lib/features/*/presentation`: pantallas. No importan `lib/data`.
- `tool/check_imports.dart`: hace cumplir las reglas anteriores, y que solo `lib/data/ads` use SDK de red.

## Privacidad en el manifiesto

`allowBackup=false` y `data_extraction_rules.xml` excluyen los documentos de la copia de seguridad (RN-07). Sin permisos de almacenamiento (RN-12). `locales_config.xml` habilita el idioma por app en Android 13 o superior.
