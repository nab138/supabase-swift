#!/bin/bash

# Script modified from https://github.com/OpenSwiftUIProject/ProtobufKit/blob/main/Scripts/build_xcframework.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PROJECT_BUILD_DIR="${PROJECT_BUILD_DIR:-"${PROJECT_ROOT}/build"}"
XCODEBUILD_BUILD_DIR="$PROJECT_BUILD_DIR/xcodebuild"
XCODEBUILD_DERIVED_DATA_PATH="$XCODEBUILD_BUILD_DIR/DerivedData"

PACKAGE_NAME="$1"

build_framework() {
    local sdk="$1"
    local destination="$2"
    local scheme="$3"

    local XCODEBUILD_ARCHIVE_PATH="./build/$scheme-$sdk.xcarchive"

    rm -rf "$XCODEBUILD_ARCHIVE_PATH"

    xcodebuild archive \
        -scheme $scheme \
        -archivePath $XCODEBUILD_ARCHIVE_PATH \
        -derivedDataPath "$XCODEBUILD_DERIVED_DATA_PATH" \
        -sdk "$sdk" \
        -destination "$destination" \
        -toolchain swift-6.0.2-RELEASE \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        INSTALL_PATH='Library/Frameworks' \
        OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface    

    FRAMEWORK_MODULES_PATH="$XCODEBUILD_ARCHIVE_PATH/Products/Library/Frameworks/$scheme.framework/Modules"
    mkdir -p "$FRAMEWORK_MODULES_PATH"
    cp -r \
        "$XCODEBUILD_DERIVED_DATA_PATH/Build/Intermediates.noindex/ArchiveIntermediates/$scheme/BuildProductsPath/Release-$sdk/$scheme.swiftmodule" \
        "$FRAMEWORK_MODULES_PATH/$scheme.swiftmodule"

    # --- NEW: Copy the binary into the .framework ---
    FRAMEWORK_BIN_SRC="$XCODEBUILD_DERIVED_DATA_PATH/Build/Intermediates.noindex/ArchiveIntermediates/$scheme/BuildProductsPath/Release-$sdk/$scheme.framework/$scheme"
    FRAMEWORK_BIN_DEST="$XCODEBUILD_ARCHIVE_PATH/Products/Library/Frameworks/$scheme.framework/$scheme"
    if [ -f "$FRAMEWORK_BIN_SRC" ]; then
        cp "$FRAMEWORK_BIN_SRC" "$FRAMEWORK_BIN_DEST"
    else
        echo "ERROR: Could not find framework binary at $FRAMEWORK_BIN_SRC"
        exit 1
    fi
}

build_framework "iphoneos" "generic/platform=iOS" "$PACKAGE_NAME"

echo "Builds completed successfully."
