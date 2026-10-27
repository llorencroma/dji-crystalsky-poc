#!/bin/sh
# Build the PoC app in a CVE directory:  ./build-apk.sh cves/CVE-2026-114354
# Needs javac, d8, aapt, zipalign, apksigner on PATH and ANDROID_JAR set to any
# platform android.jar (API >= 22). Signs with a throwaway key.
set -eu
: "${ANDROID_JAR:?set ANDROID_JAR, e.g. \$ANDROID_HOME/platforms/android-29/android.jar}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
DIR="$(cd "$1" && pwd)"
B="$DIR/build"
KS="$ROOT/poc.keystore"

rm -rf "$B" && mkdir -p "$B/classes"
javac -source 8 -target 8 -Xlint:-options -bootclasspath "$ANDROID_JAR" \
      -d "$B/classes" "$DIR"/src/poc/*.java
d8 --min-api 22 --lib "$ANDROID_JAR" --output "$B" "$B"/classes/poc/*.class
aapt package -f -M "$DIR/AndroidManifest.xml" -I "$ANDROID_JAR" -F "$B/unsigned.apk"
(cd "$B" && aapt add unsigned.apk classes.dex >/dev/null)

[ -f "$KS" ] || keytool -genkeypair -keystore "$KS" -storepass android -keypass android \
    -alias poc -keyalg RSA -keysize 2048 -validity 3650 -dname "CN=PoC" 2>/dev/null
zipalign -f 4 "$B/unsigned.apk" "$DIR/poc.apk"
apksigner sign --ks "$KS" --ks-pass pass:android --min-sdk-version 22 "$DIR/poc.apk"
rm -rf "$B" "$DIR/poc.apk.idsig"
echo "built $DIR/poc.apk"
