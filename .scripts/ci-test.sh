#!/usr/bin/env bash
set -euo pipefail

xcodebuild test \
  -quiet \
  -scheme danthorpe-networking \
  -sdk iphonesimulator \
  -derivedDataPath .build \
  -skipPackagePluginValidation \
  -destination "platform=iOS Simulator,name=iPhone 14 Pro" 
