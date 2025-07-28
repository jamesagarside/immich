# Immich ML for Jetson Nano

This directory contains the necessary files to build Immich ML for NVIDIA Jetson Nano devices with JetPack 4.6.1.

## ⚠️ Important Compatibility Warning

**This is a compatibility build that uses onnxruntime-gpu 1.11.0 instead of the required 1.17.0+**

The Jetson Nano is limited to JetPack 4.6.1, which only supports onnxruntime-gpu up to version 1.11.0. However, Immich requires onnxruntime-gpu >= 1.17.0. This means:

- ✅ Basic ML functionality may work
- ❌ Some advanced ML features may fail
- ❌ Newer model formats may not be supported
- ❌ Performance may be degraded

This build is provided as a best-effort attempt to run Immich ML on Jetson Nano devices.

## Prerequisites

### Hardware Requirements
- NVIDIA Jetson Nano Developer Kit
- JetPack 4.6.1 installed
- At least 4GB of RAM (swap may be required)
- MicroSD card with at least 32GB (64GB+ recommended)

### Software Requirements
- Docker with nvidia-docker2 runtime
- Git (for cloning the repository)

### Installing Docker and nvidia-docker on Jetson Nano

```bash
# Install Docker (if not already installed)
sudo apt-get update
sudo apt-get install -y docker.io

# Add your user to the docker group
sudo usermod -aG docker $USER

# Install nvidia-docker2
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# Test nvidia-docker
sudo docker run --rm --runtime nvidia nvidia/cuda:10.2-base-ubuntu18.04 nvidia-smi
```

## Building the Image

### Option 1: Using the Build Script (Recommended)

1. Navigate to the machine-learning directory:
```bash
cd machine-learning
```

2. Run the build script:
```bash
./build-jetson-nano.sh
```

3. Or with custom options:
```bash
./build-jetson-nano.sh -t v1.129.0-jetson-nano -n my-immich-ml
```

### Option 2: Manual Docker Build

```bash
cd machine-learning
docker build \
    --build-arg DEVICE=cuda \
    --build-arg BUILD_ID="jetson-nano-$(date +%Y%m%d%H%M%S)" \
    --build-arg BUILD_IMAGE="immich-ml-jetson-nano:latest" \
    --build-arg BUILD_SOURCE_REF="jetson-nano-custom" \
    --build-arg BUILD_SOURCE_COMMIT="$(git rev-parse HEAD)" \
    -f Dockerfile.jetson-nano \
    -t immich-ml-jetson-nano:latest \
    .
```

## Running the Container

### Basic Usage

```bash
# Run the container
docker run --runtime nvidia --rm -p 3003:3003 immich-ml-jetson-nano:latest
```

### With Docker Compose

Add this to your `docker-compose.yml`:

```yaml
version: '3.8'

services:
  immich-machine-learning:
    image: immich-ml-jetson-nano:latest
    runtime: nvidia
    ports:
      - 3003:3003
    volumes:
      - model-cache:/cache
    environment:
      - MACHINE_LEARNING_CACHE_FOLDER=/cache
      - DEVICE=cuda
    restart: unless-stopped

volumes:
  model-cache:
```

### Environment Variables

- `MACHINE_LEARNING_CACHE_FOLDER`: Directory for caching ML models (default: `/cache`)
- `DEVICE`: Device type - `cuda` or `cpu` (default: `cuda`)
- `PYTHONPATH`: Python path (default: `/usr/src`)

## Testing the Installation

### Test ONNX Runtime and CUDA

```bash
docker run --runtime nvidia --rm immich-ml-jetson-nano:latest python -c "
import onnxruntime as ort
print('ONNXRuntime version:', ort.__version__)
print('Available providers:', ort.get_available_providers())
print('CUDA available:', 'CUDAExecutionProvider' in ort.get_available_providers())
"
```

Expected output:
```
WARNING: Running on Jetson Nano with onnxruntime-gpu 1.11.0 instead of required 1.17.0+
Some ML features may not work as expected. This is a compatibility build.
ONNXRuntime version: 1.11.0
Available providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
CUDA available: True
```

### Test ML Service

```bash
# Start the container
docker run --runtime nvidia -d --name immich-ml-test -p 3003:3003 immich-ml-jetson-nano:latest

# Wait for it to start up
sleep 10

# Test the health endpoint
curl http://localhost:3003/ping

# Check logs
docker logs immich-ml-test

# Clean up
docker stop immich-ml-test
docker rm immich-ml-test
```

## Performance Optimization

### Memory Management

Jetson Nano has limited memory. Consider:

1. **Enable swap**:
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

2. **Increase GPU memory split**:
```bash
# Edit /boot/extlinux/extlinux.conf and add to APPEND line:
# nvdec_mem=1G
```

3. **Use smaller models** when possible through Immich configuration.

### Docker Resource Limits

```yaml
services:
  immich-machine-learning:
    # ... other config ...
    deploy:
      resources:
        limits:
          memory: 3g
        reservations:
          memory: 1g
```

## Troubleshooting

### Common Issues

1. **Out of memory errors**:
   - Enable swap (see above)
   - Reduce batch sizes in Immich ML configuration
   - Use CPU-only mode: `DEVICE=cpu`

2. **CUDA errors**:
   - Verify nvidia-docker2 is installed: `docker run --rm --runtime nvidia nvidia/cuda:10.2-base-ubuntu18.04 nvidia-smi`
   - Check JetPack version: `sudo apt-cache show nvidia-jetpack`

3. **Model loading failures**:
   - Some newer models may not be compatible with onnxruntime 1.11.0
   - Check Immich logs for specific model errors
   - Consider disabling problematic ML features in Immich

4. **Build failures**:
   - Ensure you have enough disk space (8GB+ free)
   - Check network connectivity for downloading packages
   - Some Python packages may fail due to version incompatibilities

### Debug Mode

Run with debug logging:

```bash
docker run --runtime nvidia --rm -e LOG_LEVEL=debug immich-ml-jetson-nano:latest
```

### Check Container Resources

```bash
# Monitor container stats
docker stats immich-ml-jetson-nano

# Check GPU utilization
sudo tegrastats
```

## Files in This Directory

- `Dockerfile.jetson-nano`: Jetson Nano specific Dockerfile
- `pyproject-jetson-nano.toml`: Modified Python dependencies for compatibility
- `build-jetson-nano.sh`: Build script with options
- `README-jetson-nano.md`: This documentation file

## Known Limitations

1. **ONNX Runtime Version**: Limited to 1.11.0 (requirement: 1.17.0+)
2. **Python Version**: Limited to 3.6 (modern version: 3.11+)
3. **CUDA Version**: Limited to 10.2 (modern version: 11.4+)
4. **Model Compatibility**: Newer ONNX models may not work
5. **Performance**: Significantly slower than modern hardware
6. **Memory**: Very limited (4GB total system memory)

## Alternative Approaches

If this compatibility build doesn't work for your use case, consider:

1. **Hardware Upgrade**: Use Jetson Xavier NX or Orin Nano (support newer JetPack)
2. **External Processing**: Run ML on a separate server, use Jetson for other tasks
3. **CPU-Only Mode**: Use `DEVICE=cpu` for better compatibility but much slower performance
4. **Immich Configuration**: Disable ML features that don't work

## Contributing

If you find improvements or fixes for Jetson Nano compatibility:

1. Test thoroughly on real hardware
2. Document any limitations or workarounds
3. Consider the impact on build time and image size
4. Submit pull requests with clear descriptions

## Support

This is a community-maintained compatibility build. Support is best-effort:

- Check existing GitHub issues for similar problems
- Include full error logs and system information
- Test with the standard Immich ML image first to isolate Jetson-specific issues
- Consider the fundamental compatibility limitations before reporting bugs

## License

Same as the main Immich project.
