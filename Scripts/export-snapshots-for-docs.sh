#!/bin/bash
# Export snapshot images to DocC Resources directories
# Copies macOS light/dark snapshots for documentation

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SNAPSHOTS_DIR="$ROOT_DIR/Tests/IronUISnapshotTests"

echo "Exporting snapshots for documentation..."

# Function to copy snapshots to a module's Resources directory
copy_snapshots() {
  local source_dir="$1"
  local dest_dir="$2"
  local prefix="$3"

  # Create Resources directory if it doesn't exist
  mkdir -p "$dest_dir"

  # Find all macOS snapshots and copy them
  if [ -d "$source_dir" ]; then
    find "$source_dir" -name "*.macOSStandard-standard-light.png" | while read -r file; do
      # Extract test name from filename (e.g., buttonVariants from buttonVariants.macOSStandard-standard-light.png)
      basename=$(basename "$file")
      testname="${basename%.macOSStandard-standard-light.png}"

      # Copy light version
      cp "$file" "$dest_dir/${prefix}-${testname}.png"

      # Copy dark version if exists
      dark_file="${file/standard-light/standard-dark}"
      if [ -f "$dark_file" ]; then
        cp "$dark_file" "$dest_dir/${prefix}-${testname}~dark.png"
      fi
    done
    echo "  Copied snapshots from $(basename "$source_dir")"
  fi
}

# IronPrimitives
PRIMITIVES_RESOURCES="$ROOT_DIR/Sources/IronPrimitives/Documentation.docc/Resources"
for dir in "$SNAPSHOTS_DIR/Primitives/__Snapshots__"/*; do
  if [ -d "$dir" ]; then
    component=$(basename "$dir" | sed 's/SnapshotTests$//')
    copy_snapshots "$dir" "$PRIMITIVES_RESOURCES" "$component"
  fi
done

# IronComponents
COMPONENTS_RESOURCES="$ROOT_DIR/Sources/IronComponents/Documentation.docc/Resources"
for dir in "$SNAPSHOTS_DIR/Components/__Snapshots__"/*; do
  if [ -d "$dir" ]; then
    component=$(basename "$dir" | sed 's/SnapshotTests$//')
    copy_snapshots "$dir" "$COMPONENTS_RESOURCES" "$component"
  fi
done

# IronLayouts
LAYOUTS_RESOURCES="$ROOT_DIR/Sources/IronLayouts/Documentation.docc/Resources"
for dir in "$SNAPSHOTS_DIR/Layouts/__Snapshots__"/*; do
  if [ -d "$dir" ]; then
    component=$(basename "$dir" | sed 's/SnapshotTests$//')
    copy_snapshots "$dir" "$LAYOUTS_RESOURCES" "$component"
  fi
done

# IronForms
FORMS_RESOURCES="$ROOT_DIR/Sources/IronForms/Documentation.docc/Resources"
for dir in "$SNAPSHOTS_DIR/Forms/__Snapshots__"/*; do
  if [ -d "$dir" ]; then
    component=$(basename "$dir" | sed 's/SnapshotTests$//')
    copy_snapshots "$dir" "$FORMS_RESOURCES" "$component"
  fi
done

# IronDataDisplay
DATADISPLAY_RESOURCES="$ROOT_DIR/Sources/IronDataDisplay/Documentation.docc/Resources"
for dir in "$SNAPSHOTS_DIR/DataDisplay/__Snapshots__"/*; do
  if [ -d "$dir" ]; then
    component=$(basename "$dir" | sed 's/SnapshotTests$//')
    copy_snapshots "$dir" "$DATADISPLAY_RESOURCES" "$component"
  fi
done

# IronNavigation
NAVIGATION_RESOURCES="$ROOT_DIR/Sources/IronNavigation/Documentation.docc/Resources"
for dir in "$SNAPSHOTS_DIR/Navigation/__Snapshots__"/*; do
  if [ -d "$dir" ]; then
    component=$(basename "$dir" | sed 's/SnapshotTests$//')
    copy_snapshots "$dir" "$NAVIGATION_RESOURCES" "$component"
  fi
done

echo "Done! Snapshots exported to Documentation.docc/Resources directories."
echo ""
echo "Images are named: ComponentName-testName.png (light) and ComponentName-testName~dark.png (dark)"
echo "Reference in DocC with: @Image(source: \"ComponentName-testName.png\", alt: \"Description\")"
