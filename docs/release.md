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
1. Create app: name «FileFlow: PDF sin internet», default language es-419, app, free.
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
