#!/bin/bash
# Run all tests for IronUI

set -e

echo "Running tests..."

swift test

echo "All tests passed!"
