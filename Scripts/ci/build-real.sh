#!/bin/bash

# To run build script for CI

xcodebuild clean build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -derivedDataPath $DERIVED_DATA_PATH \
  -scheme $SCHEME \
  -destination "$DESTINATION" \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64

# Only .app is needed.

pushd $WD

# to remove test packages to refer to the device local instead of embedded ones
# XCTAutomationSupport.framework, XCTest.framewor, XCTestCore.framework,
# XCUIAutomation.framework, XCUnit.framework
rm -rf $SCHEME-Runner.app/Frameworks/XC*.framework

mkdir Payload && mv $SCHEME-Runner.app Payload/
zip -r $ZIP_PKG_NAME Payload
popd
mv $WD/$ZIP_PKG_NAME ./
