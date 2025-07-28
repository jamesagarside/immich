#!/bin/bash

# Minimal build script for Jetson Nano
set -e

IMAGE_NAME="immich-ml-jetson"
echo "Building minimal Jetson Nano image: $IMAGE_NAME"

# Check if immich_ml directory exists
if [ ! -d "immich_ml" ]; then
    echo "ERROR: immich_ml directory not found"
    echo "Copy it from the main repository: cp -r ../immich_ml ."
    exit 1
fi

echo "Building Docker image..."
docker build -f Dockerfile.jetson-minimal -t "$IMAGE_NAME" .

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Run with: docker run --runtime nvidia --rm -p 3003:3003 $IMAGE_NAME"
else
    echo "❌ Build failed"
    exit 1
fi
