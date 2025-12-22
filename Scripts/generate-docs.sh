#!/bin/bash
# Generate DocC documentation for IronUI

set -e

echo "Generating documentation..."

swift package --allow-writing-to-directory ./docs/generated \
    generate-documentation --target IronUI \
    --output-path ./docs/generated \
    --transform-for-static-hosting \
    --hosting-base-path IronUI

echo "Documentation generated at ./docs/generated"
