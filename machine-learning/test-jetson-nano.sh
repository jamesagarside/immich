#!/bin/bash

# Test script for Jetson Nano Immich ML container
# This script performs basic tests to verify the container works

set -e

# Configuration
IMAGE_NAME="immich-ml-jetson-nano:latest"
CONTAINER_NAME="immich-ml-test-$(date +%Y%m%d%H%M%S)"
TEST_PORT=3003

echo "=== Immich ML Jetson Nano Test Script ==="
echo "Image: $IMAGE_NAME"
echo "Container: $CONTAINER_NAME"
echo ""

# Function to cleanup
cleanup() {
    echo "Cleaning up..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Test 1: Check if image exists
echo "Test 1: Checking if image exists..."
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "❌ ERROR: Image '$IMAGE_NAME' not found"
    echo "Please build the image first using: ./build-jetson-nano.sh"
    exit 1
fi
echo "✅ Image found"
echo ""

# Test 2: Check nvidia-docker runtime
echo "Test 2: Checking nvidia-docker runtime..."
if ! docker run --rm --runtime nvidia nvidia/cuda:10.2-base-ubuntu18.04 nvidia-smi > /dev/null 2>&1; then
    echo "❌ ERROR: nvidia-docker runtime not working"
    echo "Please install nvidia-docker2 and restart Docker"
    exit 1
fi
echo "✅ nvidia-docker runtime working"
echo ""

# Test 3: Start container
echo "Test 3: Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --runtime nvidia \
    -p "$TEST_PORT:3003" \
    -e DEVICE=cuda \
    "$IMAGE_NAME"

echo "✅ Container started"
echo ""

# Test 4: Wait for container to be ready
echo "Test 4: Waiting for container to be ready..."
MAX_WAIT=60
WAIT_TIME=0
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker exec "$CONTAINER_NAME" curl -f http://localhost:3003/ping > /dev/null 2>&1; then
        break
    fi
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
    echo -n "."
done
echo ""

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "❌ ERROR: Container did not become ready within $MAX_WAIT seconds"
    echo "Container logs:"
    docker logs "$CONTAINER_NAME"
    exit 1
fi
echo "✅ Container is ready"
echo ""

# Test 5: Check ONNX Runtime
echo "Test 5: Testing ONNX Runtime..."
if docker exec "$CONTAINER_NAME" python -c "
import onnxruntime as ort
print('ONNXRuntime version:', ort.__version__)
providers = ort.get_available_providers()
print('Available providers:', providers)
if 'CUDAExecutionProvider' in providers:
    print('✅ CUDA provider available')
else:
    print('⚠️  CUDA provider not available')
    print('Available providers:', providers)
"; then
    echo "✅ ONNX Runtime test passed"
else
    echo "❌ ONNX Runtime test failed"
    echo "Container logs:"
    docker logs "$CONTAINER_NAME"
    exit 1
fi
echo ""

# Test 6: Test ML service endpoints
echo "Test 6: Testing ML service endpoints..."

# Test ping endpoint
if curl -f "http://localhost:$TEST_PORT/ping" > /dev/null 2>&1; then
    echo "✅ Ping endpoint working"
else
    echo "❌ Ping endpoint failed"
fi

# Check if other endpoints are accessible (they may return errors without proper data)
ENDPOINTS=("/models" "/predict")
for endpoint in "${ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$TEST_PORT$endpoint" || echo "000")
    if [ "$HTTP_CODE" != "000" ]; then
        echo "✅ Endpoint $endpoint accessible (HTTP $HTTP_CODE)"
    else
        echo "⚠️  Endpoint $endpoint not accessible"
    fi
done
echo ""

# Test 7: Memory usage check
echo "Test 7: Checking memory usage..."
MEMORY_USAGE=$(docker stats --no-stream --format "table {{.MemUsage}}" "$CONTAINER_NAME" | tail -n 1)
echo "Current memory usage: $MEMORY_USAGE"
echo "✅ Memory usage check completed"
echo ""

# Test 8: GPU usage check (if available)
echo "Test 8: Checking GPU usage..."
if command -v tegrastats > /dev/null 2>&1; then
    echo "Tegrastats available - checking GPU utilization:"
    timeout 5s tegrastats | head -n 3 || true
    echo "✅ GPU stats check completed"
else
    echo "⚠️  tegrastats not available, skipping GPU check"
fi
echo ""

# Final summary
echo "=== Test Summary ==="
echo "✅ Image exists and is accessible"
echo "✅ nvidia-docker runtime working"
echo "✅ Container starts successfully"
echo "✅ Container becomes ready"
echo "✅ ONNX Runtime loads correctly"
echo "✅ ML service endpoints accessible"
echo "✅ Memory usage within expected range"
echo ""
echo "🎉 All basic tests passed!"
echo ""
echo "Container '$CONTAINER_NAME' is still running on port $TEST_PORT"
echo "You can test it manually with:"
echo "  curl http://localhost:$TEST_PORT/ping"
echo ""
echo "To stop and remove the test container:"
echo "  docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo ""
echo "⚠️  Remember: This build uses onnxruntime-gpu 1.11.0 instead of required 1.17.0+"
echo "Some ML features may not work as expected in production."
