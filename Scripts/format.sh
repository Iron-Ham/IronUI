#!/bin/bash
# Format all Swift files using Airbnb Swift Style Guide

set -e

echo "Formatting Swift files..."

swift package --allow-writing-to-package-directory format

echo "Formatting complete!"
