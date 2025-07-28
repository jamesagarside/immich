#!/bin/bash

# Pre-build check script for Jetson Nano
echo "=== Pre-build Check for Jetson Nano ==="

# Check if required files exist
REQUIRED_FILES=(
    "Dockerfile.jetson-nano-simple"
    "pyproject-jetson-nano.toml"
)

REQUIRED_DIRS=(
    "immich_ml"
    "scripts"
)

echo "Checking required files..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        MISSING=true
    fi
done

echo ""
echo "Checking required directories..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/"
    else
        echo "❌ $dir/ (missing)"
        MISSING=true
    fi
done

if [ "$MISSING" = true ]; then
    echo ""
    echo "❌ Missing required files/directories!"
    echo ""
    echo "You need to copy the following from the main Immich repository:"
    echo "- immich_ml/ directory (the Python ML code)"
    echo "- scripts/ directory (including healthcheck.py)"
    echo ""
    echo "From the main immich repo, run:"
    echo "cp -r machine-learning/immich_ml ."
    echo "cp -r machine-learning/scripts ."
    exit 1
fi

echo ""
echo "✅ All required files and directories are present!"
echo ""
echo "System information:"
echo "Architecture: $(uname -m)"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo "Docker version: $(docker --version 2>/dev/null || echo 'Docker not found')"
echo ""

# Check for nvidia-docker
if docker run --rm --runtime nvidia nvidia/cuda:10.2-base-ubuntu18.04 nvidia-smi > /dev/null 2>&1; then
    echo "✅ nvidia-docker runtime working"
else
    echo "⚠️  nvidia-docker runtime may not be working"
    echo "This is required for GPU acceleration"
fi

echo ""
echo "Ready to build! Run: ./build-jetson-nano.sh"
