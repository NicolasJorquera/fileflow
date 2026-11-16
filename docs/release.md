# Release (H10)

## Build
```bash
PUB_HOSTED_URL=https://pub.dev flutter build appbundle --release --flavor prod -t lib/main.dart
```
Output: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

## Upload key
- `android/key.properties` (gitignored) points to the upload keystore at `~/Personal/fileflow-keys/upload-keystore.jks` (alias `upload`).
- Keep a copy of both files outside this Mac (password manager or encrypted drive). With Play App Signing a lost upload key can be reset, but it takes days.
- Without `key.properties`, release builds are signed with the debug key (CI, local runs) and Play rejects them.

## Checks done (2026-11-10)
- targetSdk 36, minSdk 24.
- 64-bit native libraries (arm64-v8a, x86_64) aligned to 16 KB or more.
- Ads: prod uses the FileFlow AdMob units; dev uses Google's test units.

## Identity
- Package: `com.gonisoma.fileflow` (iOS bundle id too). Kotlin namespace stays `io.github.nicolasjorquera.fileflow`.
- Version 1.0.0+1. Raise the build number (`+N`) on every upload.

## Store graphics
- `docs/store/graphics/icon-512.png`, `feature-{es,en,pt}.png` (1024x500), `screenshots/{es,en,pt}/` (1080x2160).
- Regenerate: `flutter test tool/brand/render_brand_test.dart` and `FLUTTER_ROOT=<flutter> flutter test tool/brand/screenshots_test.dart`.
- After re-rendering, strip alpha from the iOS icons (App Store rejects it): `sips` to JPEG and back, as done on 2026-11-10.

## Play Console, first release
1. Create app: name «FileFlow: PDF sin internet», default language es-419, app, free (free apps can sell in-app products; Play shows «Contains ads · In-app purchases»).
2. Set up your app:
   - Privacy policy: https://nicolasjorquera.github.io/fileflow/privacy/
   - App access: all functionality available without special access.
   - Ads: yes, contains ads.
   - Content rating: questionnaire, category «Utility, productivity, communication or other»; no sensitive content.
   - Target audience: 18+ (not directed at children).
   - Data safety: answers in `docs/data-safety.md`.
   - Advertising ID: yes, for advertising.
   - Government apps: no. Financial features: none. Health: no.
3. Store listing: texts in `docs/store/*.md`, graphics above; category Productivity; contact email.
4. Production › Create release: Play App Signing on (Google manages the app key), upload the AAB, release notes from the listing files, countries, roll out. Review usually takes a few days.
5. AdMob: in the AdMob app, link it to the Play listing once it is live, and publish `app-ads.txt` on the developer website set in Play (root of that domain).

## In-app product «Sin anuncios»
The app is free with ads and sells one non-consumable product that removes every ad (Google Play Billing, no backend).

1. Play Console › Monetize › Products › In-app products: create `fileflow_remove_ads` (this exact ID), name «Sin anuncios» / «No ads» / «Sem anúncios», price, then Activate. Play needs an uploaded build with the BILLING permission (added by `in_app_purchase`) before it lets you create products.
2. The app always shows the price Play returns, localized; there is no price in the code. Without the product (or without Play or a connection) the card in Ajustes says Google Play is not available and nothing else changes.
3. Test with license testers (Play Console › Settings › License testing) on an internal or closed testing build installed from Play: buy, cancel, «slow test card» for a pending purchase, refund from Order management (the app revokes on the next start), «Restaurar compra» after reinstalling.
4. State: saved in the preferences (`ads_removed`) and checked with Play on every start; when Play answers it wins, offline the saved state stays. Purchases are acknowledged by the app (otherwise Play refunds them after 3 days). There is no server-side validation: a tampered device could unlock it (accepted risk, no backend).

## Automatic publishing (GitHub Actions)
`.github/workflows/play-store.yml` builds the prod flavor, signs it and uploads it with the Play service account.

| Trigger | Track | Status |
|---|---|---|
| Merge to `main` | internal | completed |
| `v*` tag (e.g. `v1.0.1`) | `PLAY_TAG_TRACK` variable, `alpha` (closed testing) by default | completed; staged at 20 % when the variable is `production` |
| Manual run (Actions → "Publish to Play") | any | any |

- **versionName** comes from `pubspec.yaml`; a tag must match it. **versionCode** is the run number plus `VERSION_CODE_OFFSET` (100 by default), so it always grows and stays above the 1 uploaded by hand. The `+N` in `pubspec.yaml` only matters for manual builds.
- Runs the tests and refuses to upload an AAB signed with the debug key. Keeps the AAB and `mapping.txt` as a run artifact for 30 days.
- Once Play grants production access (12 testers × 14 days in closed testing), set the `PLAY_TAG_TRACK` variable to `production`.
- Setup in GitHub → Settings → Environments → `play-store`: secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (the values in `android/key.properties`) and `PLAY_SERVICE_ACCOUNT_JSON`.
