#!/bin/bash

# Build script for Immich ML on Jetson Nano
# This script builds a compatible version of Immich ML for Jetson Nano devices
# with JetPack 4.6.1 and onnxruntime-gpu 1.11.0

set -e

echo "=== Building Immich ML for Jetson Nano ==="
echo "WARNING: This builds with onnxruntime-gpu 1.11.0 instead of the required 1.17.0+"
echo "Some ML features may not work as expected."
echo ""

# Check if we're on arm64 architecture
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "WARNING: Building on $ARCH architecture. This is intended for aarch64/arm64 (Jetson devices)."
    echo "The build may fail or produce incompatible binaries."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Default values
IMAGE_NAME="immich-ml-jetson-nano"
TAG="latest"
DEVICE="cuda"
DOCKERFILE="Dockerfile.jetson-nano"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -t, --tag TAG        Docker image tag (default: latest)"
            echo "  -n, --name NAME      Docker image name (default: immich-ml-jetson-nano)"
            echo "  --device DEVICE      Device type: cuda, cpu (default: cuda)"
            echo "  -f, --file FILE      Dockerfile to use (default: Dockerfile.jetson-nano)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build with defaults"
            echo "  $0 -t v1.129.0 -n my-immich-ml      # Custom tag and name"
            echo "  $0 --device cpu                      # Build for CPU only"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "Building Docker image: $IMAGE_NAME:$TAG"
echo "Device: $DEVICE"
echo "Dockerfile: $DOCKERFILE"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running or not accessible"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo "ERROR: Dockerfile '$DOCKERFILE' not found"
    echo "Available Dockerfiles:"
    ls -la Dockerfile*
    exit 1
fi

# Build the image
echo "Starting build..."
docker build \
    --build-arg DEVICE="$DEVICE" \
    --build-arg BUILD_ID="jetson-nano-$(date +%Y%m%d%H%M%S)" \
    --build-arg BUILD_IMAGE="$IMAGE_NAME:$TAG" \
    --build-arg BUILD_SOURCE_REF="jetson-nano-custom" \
    --build-arg BUILD_SOURCE_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')" \
    -f "$DOCKERFILE" \
    -t "$IMAGE_NAME:$TAG" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "=== Build completed successfully! ==="
    echo "Image: $IMAGE_NAME:$TAG"
    echo ""
    echo "To run the container:"
    echo "docker run --runtime nvidia --rm -p 3003:3003 $IMAGE_NAME:$TAG"
    echo ""
    echo "To test the container:"
    echo "docker run --runtime nvidia --rm $IMAGE_NAME:$TAG python -c \"import onnxruntime as ort; print('ONNXRuntime version:', ort.__version__); print('CUDA available:', 'CUDAExecutionProvider' in ort.get_available_providers())\""
    echo ""
    echo "IMPORTANT NOTES:"
    echo "- This build uses onnxruntime-gpu 1.11.0 instead of the required 1.17.0+"
    echo "- Some ML features may not work as expected"
    echo "- This is specifically for Jetson Nano with JetPack 4.6.1"
    echo "- Make sure you have nvidia-docker runtime installed"
else
    echo ""
    echo "=== Build failed! ==="
    echo "Check the error messages above for details."
    exit 1
fi
