#!/bin/bash

# Script to deploy Jetson Nano files to remote host
# Usage: ./deploy-to-jetson.sh [jetson-host]

JETSON_HOST="${1:-jetson@10.80.0.25}"
REMOTE_DIR="/home/jetson/immich-ml-jetson"

echo "=== Deploying Jetson Nano files to $JETSON_HOST ==="

# Create remote directory
ssh "$JETSON_HOST" "mkdir -p $REMOTE_DIR"

# Copy Jetson-specific files
echo "Copying Jetson Nano specific files..."
scp Dockerfile.jetson-nano "$JETSON_HOST:$REMOTE_DIR/"
scp pyproject-jetson-nano.toml "$JETSON_HOST:$REMOTE_DIR/"
scp build-jetson-nano.sh "$JETSON_HOST:$REMOTE_DIR/"
scp test-jetson-nano.sh "$JETSON_HOST:$REMOTE_DIR/"
scp docker-compose.jetson-nano.yml "$JETSON_HOST:$REMOTE_DIR/"
scp .env.jetson-nano.example "$JETSON_HOST:$REMOTE_DIR/"
scp README-jetson-nano.md "$JETSON_HOST:$REMOTE_DIR/"

# Copy necessary source files
echo "Copying source files..."
scp -r immich_ml "$JETSON_HOST:$REMOTE_DIR/" 2>/dev/null || echo "immich_ml directory not found - you may need to copy this manually"
scp -r scripts "$JETSON_HOST:$REMOTE_DIR/" 2>/dev/null || echo "scripts directory not found - you may need to copy this manually"

# Make scripts executable
ssh "$JETSON_HOST" "chmod +x $REMOTE_DIR/*.sh"

echo ""
echo "=== Deployment Complete ==="
echo "Files deployed to: $JETSON_HOST:$REMOTE_DIR"
echo ""
echo "Next steps:"
echo "1. SSH to your Jetson: ssh $JETSON_HOST"
echo "2. Navigate to: cd $REMOTE_DIR"
echo "3. Build the image: ./build-jetson-nano.sh"
echo "4. Test the image: ./test-jetson-nano.sh"
echo ""
echo "To connect and build:"
echo "ssh $JETSON_HOST 'cd $REMOTE_DIR && ./build-jetson-nano.sh'"
