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

## Before the first upload
- Final `applicationId` (cannot change after publishing) and app name.
- Play Console: app access (no login), ads = yes, content rating, target audience (not children), Data safety (`docs/data-safety.md`), privacy policy URL.
- Closed test: at least 12 testers for 14 days.
