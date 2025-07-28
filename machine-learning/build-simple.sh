#!/bin/bash
# Ultra-simple build for Jetson Nano

echo "Building ultra-simple Jetson image..."

if [ ! -d "immich_ml" ]; then
    echo "Need immich_ml directory. Copy from: cp -r ../immich_ml ."
    exit 1
fi

docker build -f Dockerfile.simple -t jetson-ml-simple .
echo "Done! Run with: docker run --runtime nvidia -p 3003:3003 jetson-ml-simple"
