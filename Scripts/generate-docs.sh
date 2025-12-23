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

        # Copy documentation content (HTML pages)
        if [ -d "$archive/documentation/$module_lower" ]; then
            cp -r "$archive/documentation/$module_lower" "$OUTPUT_DIR/documentation/"
        fi

        # Copy images for this module
        if [ -d "$archive/images/$module" ]; then
            mkdir -p "$OUTPUT_DIR/images/"
            cp -r "$archive/images/$module" "$OUTPUT_DIR/images/"
            echo "  Copied images for $module"
        fi

        # Copy tutorials data and HTML pages
        if [ -d "$archive/data/tutorials" ]; then
            mkdir -p "$OUTPUT_DIR/data/tutorials"
            cp -r "$archive/data/tutorials"/* "$OUTPUT_DIR/data/tutorials/" 2>/dev/null || true
            echo "  Copied tutorial data for $module"
        fi
        if [ -d "$archive/tutorials" ]; then
            mkdir -p "$OUTPUT_DIR/tutorials"
            cp -r "$archive/tutorials"/* "$OUTPUT_DIR/tutorials/" 2>/dev/null || true
            echo "  Copied tutorial pages for $module"
        fi

        # Copy index data for this module (for sidebar navigation)
        if [ -f "$archive/index/index.json" ]; then
            mkdir -p "$OUTPUT_DIR/index-modules"
            cp "$archive/index/index.json" "$OUTPUT_DIR/index-modules/$module_lower-index.json"
        fi

        echo "  Merged $module"
    fi
done

# Merge all module indices into a combined index.json for sidebar navigation
echo "Merging sidebar indices..."
python3 << 'PYTHON_SCRIPT'
import json
import os

output_dir = "./docs"
index_modules_dir = os.path.join(output_dir, "index-modules")

# Collect all module indices
all_archives = []
all_modules = []

for filename in sorted(os.listdir(index_modules_dir)):
    if filename.endswith("-index.json"):
        filepath = os.path.join(index_modules_dir, filename)
        with open(filepath, 'r') as f:
            data = json.load(f)
            all_archives.extend(data.get("includedArchiveIdentifiers", []))
            all_modules.extend(data.get("interfaceLanguages", {}).get("swift", []))

# Create merged index
merged_index = {
    "includedArchiveIdentifiers": all_archives,
    "interfaceLanguages": {
        "swift": all_modules
    },
    "schemaVersion": {"major": 0, "minor": 1, "patch": 2}
}

# Write merged index
with open(os.path.join(output_dir, "index", "index.json"), 'w') as f:
    json.dump(merged_index, f)

print(f"  Merged {len(all_archives)} modules into sidebar")
PYTHON_SCRIPT

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
