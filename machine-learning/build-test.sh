#!/bin/bash
# Test build for Jetson Nano - just basic container

echo "Building test container (no ONNX Runtime)..."
docker build -f Dockerfile.test -t jetson-test .

if [ $? -eq 0 ]; then
    echo "✅ Test build successful!"
    echo ""
    echo "Test the container:"
    echo "docker run --rm -p 3003:3003 jetson-test"
    echo ""
    echo "Then visit: http://localhost:3003"
    echo "Or test: curl http://localhost:3003/ping"
else
    echo "❌ Build failed"
fi
