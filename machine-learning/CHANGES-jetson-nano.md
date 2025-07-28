# Jetson Nano Compatibility Changes Summary

This document summarizes the changes made to support NVIDIA Jetson Nano devices with JetPack 4.6.1.

## Key Compatibility Issues Addressed

### 1. ONNX Runtime Version Compatibility

- **Problem**: Immich requires onnxruntime-gpu >= 1.17.0, but Jetson Nano (JetPack 4.6.1) only supports up to 1.11.0
- **Solution**: Modified dependencies to use onnxruntime-gpu 1.11.0 with compatibility warnings

### 2. Python Version Compatibility

- **Problem**: Immich requires Python >= 3.10, but JetPack 4.6.1 supports up to Python 3.6
- **Solution**: Modified Python version requirements and package versions for Python 3.6 compatibility

### 3. CUDA Version Compatibility

- **Problem**: Original Dockerfile uses CUDA 11.4, but Jetson Nano uses CUDA 10.2
- **Solution**: Used appropriate base images and CUDA paths for JetPack 4.6.1

### 4. Base Image Compatibility

- **Problem**: Original uses l4t-base:35.4.1 (JetPack 5.2.x), incompatible with Jetson Nano
- **Solution**: Changed to l4t-base:32.7.1 and l4t-cuda:10.2.460-runtime-ubuntu18.04

## Files Created

### 1. `Dockerfile.jetson-nano`

- Jetson Nano specific Dockerfile
- Uses Python 3.6 and onnxruntime-gpu 1.11.0
- Includes compatibility warnings

### 2. `pyproject-jetson-nano.toml`

- Modified Python dependencies for Jetson Nano
- Adjusted version constraints for Python 3.6
- Reduced onnxruntime requirements to 1.11.0

### 3. `build-jetson-nano.sh`

- Automated build script with options
- Architecture detection and warnings
- Customizable build parameters

### 4. `test-jetson-nano.sh`

- Comprehensive test script
- Validates container functionality
- Checks CUDA and ONNX Runtime integration

### 5. `docker-compose.jetson-nano.yml`

- Docker Compose configuration for Jetson Nano
- Includes nvidia runtime and resource limits
- Memory-optimized for 4GB systems

### 6. `.env.jetson-nano.example`

- Environment configuration template
- Jetson Nano specific settings
- Performance optimization options

### 7. `README-jetson-nano.md`

- Comprehensive documentation
- Installation instructions
- Troubleshooting guide
- Performance optimization tips

## Modified Files

### 1. `Dockerfile` (Original)

- Modified the original to show the Jetson Nano compatible version
- This change would typically be in a separate branch or PR

## Technical Details

### Package Version Changes

```diff
- requires-python = ">=3.10,<4.0"
+ requires-python = ">=3.6,<4.0"

- cuda = ["onnxruntime-gpu>=1.17.0,<2"]
+ cuda = ["onnxruntime-gpu>=1.11.0,<1.12"]

- python_version = "3.11"
+ python_version = "3.6"

- target-version = "py311"
+ target-version = "py36"
```

### Docker Base Images

```diff
- FROM nvcr.io/nvidia/l4t-base:35.4.1
+ FROM nvcr.io/nvidia/l4t-base:32.7.1

- FROM nvcr.io/nvidia/l4t-cuda:11.4.19-runtime
+ FROM nvcr.io/nvidia/l4t-cuda:10.2.460-runtime-ubuntu18.04
```

### CUDA Environment

```diff
- ENV LD_LIBRARY_PATH=/usr/local/cuda-11/compat:$LD_LIBRARY_PATH
+ ENV LD_LIBRARY_PATH=/usr/local/cuda-10.2/lib64:$LD_LIBRARY_PATH
```

### ONNX Runtime Installation

```diff
- wget ... onnxruntime_gpu-1.18.0-cp311-cp311-linux_aarch64.whl
+ wget ... onnxruntime_gpu-1.11.0-cp36-cp36m-linux_aarch64.whl
```

## Build Process

### For Jetson Nano

```bash
# Build the image
./build-jetson-nano.sh

# Test the image
./test-jetson-nano.sh

# Run with Docker Compose
cp .env.jetson-nano.example .env
# Edit .env with your settings
docker-compose -f docker-compose.jetson-nano.yml up -d
```

### For Other Platforms

```bash
# Use the original Dockerfile for newer Jetson devices or x86_64
docker build -f Dockerfile -t immich-ml:latest .
```

## Limitations and Warnings

### Known Issues

1. **ONNX Model Compatibility**: Some newer ONNX models may not work with version 1.11.0
2. **Performance**: Significantly slower than modern hardware
3. **Memory**: Limited to 4GB system memory, requires careful optimization
4. **Feature Support**: Some Immich ML features may be disabled or non-functional

### Compatibility Matrix

| Platform         | JetPack | Python | ONNX Runtime | CUDA  | Status                  |
| ---------------- | ------- | ------ | ------------ | ----- | ----------------------- |
| Jetson Nano      | 4.6.1   | 3.6    | 1.11.0       | 10.2  | ⚠️ Compatible (Limited) |
| Jetson Xavier NX | 5.0+    | 3.8+   | 1.15+        | 11.4+ | ✅ Recommended          |
| Jetson Orin      | 5.1+    | 3.10+  | 1.17+        | 11.4+ | ✅ Full Support         |

## Testing Recommendations

### Before Deployment

1. Run the test script: `./test-jetson-nano.sh`
2. Verify CUDA functionality
3. Test with your specific models
4. Monitor memory usage under load
5. Test with actual Immich integration

### Performance Testing

```bash
# Monitor system resources
sudo tegrastats

# Check Docker container stats
docker stats immich-ml-jetson-nano

# Test ML endpoints
curl http://localhost:3003/ping
```

## Deployment Considerations

### Production Deployment

1. **Memory**: Ensure swap is enabled (4GB recommended)
2. **Storage**: Use fast storage (NVMe SSD if possible)
3. **Cooling**: Ensure adequate cooling for sustained workloads
4. **Monitoring**: Monitor GPU/CPU temperatures and memory usage
5. **Backup**: Regular backups of model cache and configurations

### Scaling Limitations

- Single GPU device (no multi-GPU support)
- Limited concurrent processing capability
- Memory constraints limit batch sizes
- Consider offloading heavy ML tasks to more powerful hardware

## Future Improvements

### Potential Enhancements

1. **Model Optimization**: Quantized models for better performance
2. **Memory Management**: Better memory pooling and garbage collection
3. **Selective Features**: Disable unused ML features to save resources
4. **Caching**: Improved model caching strategies
5. **Monitoring**: Better resource monitoring and alerting

### Community Contributions

- Report compatibility issues with specific models
- Performance optimization suggestions
- Documentation improvements
- Testing on different configurations

## Support and Resources

### Official Resources

- [NVIDIA Jetson Zoo](https://elinux.org/Jetson_Zoo)
- [JetPack Documentation](https://docs.nvidia.com/jetson/)
- [Immich Documentation](https://immich.app/docs)

### Community Resources

- Immich Discord/Forum for ML-specific questions
- NVIDIA Jetson Developer Forums
- GitHub issues for bug reports and feature requests

This compatibility layer provides a foundation for running Immich ML on Jetson Nano devices, despite the fundamental version constraints. While not all features may work perfectly, it offers a viable path for basic ML functionality on these devices.
