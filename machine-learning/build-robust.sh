#!/bin/bash
# Robust build that handles missing files gracefully

echo "Building robust Jetson container..."

if [ ! -d "immich_ml" ]; then
    echo "⚠️  immich_ml directory not found - will create test container"
    echo "   To build with full ML support, copy: cp -r ../immich_ml ."
fi

docker build -f Dockerfile.robust -t jetson-robust .

if [ $? -eq 0 ]; then
    echo "✅ Robust build successful!"
    echo ""
    echo "Run the container:"
    echo "docker run --runtime nvidia --rm -p 3003:3003 jetson-robust"
    echo ""
    echo "Test endpoints:"
    echo "curl http://localhost:3003/"
    echo "curl http://localhost:3003/ping" 
    echo "curl http://localhost:3003/test  # Check ONNX Runtime"
else
    echo "❌ Build failed"
fi
