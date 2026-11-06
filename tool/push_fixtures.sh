#!/bin/sh
# Copies the engine fixtures into the dev app's files folder so the on-device
# tests can compare with phase 1 (integration_test/h6_test.dart). The dev app
# must be installed (debug build, so run-as works).
#
#   tool/push_fixtures.sh            uses $ANDROID_SERIAL
set -eu
PKG=io.github.nicolasjorquera.fileflow.dev
SRC=packages/pdf_engine/test/fixtures
for f in scan_color_10p.pdf scan_gray_10p.pdf mixed_12p.pdf text_50p.pdf; do
  adb push "$SRC/$f" "/data/local/tmp/$f" >/dev/null
  adb shell "run-as $PKG sh -c 'mkdir -p files/it_fixtures && cat /data/local/tmp/$f > files/it_fixtures/$f'"
  adb shell rm "/data/local/tmp/$f"
done
echo "fixtures copied to $PKG"
