#!/bin/sh
# Print model, firmware and the platform properties the PoCs rely on. Read-only.
set -u
adb get-serialno >/dev/null 2>&1 || { echo "no adb device"; exit 1; }
p() { printf '%-26s %s\n' "$1" "$(adb shell "$2" | tr -d '\r')"; }

p device         'getprop ro.product.device'
p android        'getprop ro.build.version.release'
p fingerprint    'getprop ro.build.fingerprint'
p kernel         'cat /proc/version'
p selinux        'getenforce'                      # expect Disabled
p ro.adb.secure  'getprop ro.adb.secure'           # expect 0
p usb.config     'getprop persist.sys.usb.config'  # expect mass_storage,adb,acm
p /system        "grep ' /system ' /proc/mounts"   # expect ro
