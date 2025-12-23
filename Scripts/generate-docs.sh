#!/bin/bash
# Generate DocC documentation for IronUI and all sub-modules

set -e

OUTPUT_DIR="./docs"
MODULES=(
    "IronCore"
    "IronPrimitives"
    "IronComponents"
    "IronLayouts"
    "IronNavigation"
    "IronForms"
    "IronDataDisplay"
    "IronKitBridge"
    "IronUI"
)

echo "Generating documentation for all modules..."

# Build target flags
TARGET_FLAGS=""
for module in "${MODULES[@]}"; do
    TARGET_FLAGS="$TARGET_FLAGS --target $module"
done

# Generate documentation for all targets
swift package --allow-writing-to-directory "$OUTPUT_DIR" \
    generate-documentation \
    $TARGET_FLAGS \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path IronUI \
    --output-path "$OUTPUT_DIR"

echo "Merging module documentation..."

# Merge each module's documentation into the unified structure
for module in "${MODULES[@]}"; do
    module_lower=$(echo "$module" | tr '[:upper:]' '[:lower:]')
    archive="$OUTPUT_DIR/${module}.doccarchive"

    if [ -d "$archive" ]; then
        # Copy data/documentation content
        if [ -d "$archive/data/documentation/$module_lower" ]; then
            cp -r "$archive/data/documentation/$module_lower" "$OUTPUT_DIR/data/documentation/"
            cp "$archive/data/documentation/$module_lower.json" "$OUTPUT_DIR/data/documentation/"
        fi

        # Copy documentation content
        if [ -d "$archive/documentation/$module_lower" ]; then
            cp -r "$archive/documentation/$module_lower" "$OUTPUT_DIR/documentation/"
        fi

        echo "  Merged $module"
    fi
done

# Clean up individual .doccarchive folders
echo "Cleaning up..."
rm -rf "$OUTPUT_DIR"/*.doccarchive

echo "Documentation generated at $OUTPUT_DIR"
echo ""
echo "Available modules:"
for module in "${MODULES[@]}"; do
    module_lower=$(echo "$module" | tr '[:upper:]' '[:lower:]')
    echo "  - /documentation/$module_lower/"
done
