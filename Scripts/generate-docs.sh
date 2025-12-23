#!/bin/bash
# Generate combined DocC documentation for IronUI and all sub-modules

set -e

OUTPUT_DIR="./docs"
ARCHIVE_PATH=".build/plugins/Swift-DocC/outputs/IronUI.doccarchive"

echo "Generating combined documentation..."

swift package generate-documentation \
    --enable-experimental-combined-documentation \
    --enable-mentioned-in \
    --enable-parameters-and-returns-validation \
    --target IronCore \
    --target IronPrimitives \
    --target IronComponents \
    --target IronLayouts \
    --target IronNavigation \
    --target IronForms \
    --target IronDataDisplay \
    --target IronUI \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path IronUI

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Combined archive not found at $ARCHIVE_PATH"
    exit 1
fi

echo "Refreshing $OUTPUT_DIR from combined archive..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
cp -R "$ARCHIVE_PATH"/* "$OUTPUT_DIR"/

echo "Documentation generated at $OUTPUT_DIR"
