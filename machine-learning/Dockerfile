ARG DEVICE=cuda

# For Jetson Nano - JetPack 4.6.1 (l4t-base:32.7.1)
FROM nvcr.io/nvidia/l4t-base:32.7.1 AS builder

ARG DEVICE
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

# Install Python 3.6 and build dependencies for JetPack 4.6.1
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    ca-certificates \
    python3.6 \
    python3.6-dev \
    python3-venv \
    python3-pip \
    libcudnn8-dev \
    libhdf5-serial-dev \
    hdf5-tools \
    libhdf5-dev \
    zlib1g-dev \
    zip \
    libjpeg8-dev \
    liblapack-dev \
    libblas-dev \
    gfortran && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.6 as default and create venv
RUN python3.6 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools==49.6.0

# Install ONNX Runtime GPU 1.11.0 for JetPack 4.6.1 (maximum supported version)
RUN wget -q -O onnxruntime_gpu-1.11.0-cp36-cp36m-linux_aarch64.whl \
    https://nvidia.box.com/shared/static/8w3y1ksblr8nml1zlyp3rg89lx5kthay.whl && \
    /opt/venv/bin/pip install onnxruntime_gpu-1.11.0-cp36-cp36m-linux_aarch64.whl

# Install compatible numpy and other base packages for JetPack 4.6.1
RUN /opt/venv/bin/pip install \
    numpy==1.19.4 \
    future==0.18.2 \
    mock==3.0.5 \
    h5py==2.10.0 \
    Cython

# Create a minimal pyproject.toml for Jetson Nano compatibility
COPY pyproject.toml ./
RUN sed -i 's/>=3.10,<4.0/>=3.6,<4.0/' pyproject.toml && \
    sed -i 's/onnxruntime-gpu>=1.17.0,<2/onnxruntime-gpu>=1.11.0,<2/' pyproject.toml && \
    sed -i 's/onnxruntime>=1.15.0,<2/onnxruntime>=1.11.0,<2/' pyproject.toml

# Install Python dependencies manually (avoiding uv for compatibility)
RUN /opt/venv/bin/pip install \
    aiocache==0.12.1 \
    fastapi==0.95.2 \
    ftfy==6.1.1 \
    gunicorn==21.1.0 \
    "huggingface-hub>=0.20.1,<1.0" \
    "insightface>=0.7.3,<1.0" \
    "opencv-python-headless>=4.7.0.72,<5.0" \
    orjson==3.9.5 \
    "pillow>=9.5.0,<11.0" \
    "pydantic>=2.0.0,<3" \
    "pydantic-settings>=2.5.2,<3" \
    "python-multipart>=0.0.6,<1.0" \
    rich==13.4.2 \
    "tokenizers>=0.15.0,<1.0" \
    "uvicorn[standard]>=0.22.0,<1.0"

# runtime stage for Jetson Nano
FROM nvcr.io/nvidia/l4t-cuda:10.2.460-runtime-ubuntu18.04

# Install runtime dependencies for JetPack 4.6.1
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.6 \
    python3-pip \
    libcudnn8-dev \
    libhdf5-serial-dev \
    hdf5-tools \
    libhdf5-dev \
    zlib1g-dev \
    libjpeg8-dev \
    liblapack-dev \
    libblas-dev \
    gfortran \
    tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set CUDA 10.2 environment for Jetson Nano
ENV LD_LIBRARY_PATH=/usr/local/cuda-10.2/lib64:$LD_LIBRARY_PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONPATH=/usr/src \
    DEVICE=${DEVICE} \
    VIRTUAL_ENV=/opt/venv \
    MACHINE_LEARNING_CACHE_FOLDER=/cache

COPY --from=builder /opt/venv /opt/venv

# Re-install onnxruntime-gpu in runtime stage to ensure it's available
RUN wget -q -O onnxruntime_gpu-1.11.0-cp36-cp36m-linux_aarch64.whl \
    https://nvidia.box.com/shared/static/8w3y1ksblr8nml1zlyp3rg89lx5kthay.whl && \
    /opt/venv/bin/pip install onnxruntime_gpu-1.11.0-cp36-cp36m-linux_aarch64.whl && \
    rm onnxruntime_gpu-1.11.0-cp36-cp36m-linux_aarch64.whl
 
RUN echo "hard core 0" >> /etc/security/limits.conf && \
    echo "fs.suid_dumpable 0" >> /etc/sysctl.conf && \
    echo 'ulimit -S -c 0 > /dev/null 2>&1' >> /etc/profile

WORKDIR /usr/src
COPY scripts/healthcheck.py .
COPY immich_ml immich_ml

# Add compatibility warning for Jetson Nano
RUN echo "#!/bin/bash" > /usr/local/bin/jetson-nano-warning.sh && \
    echo "echo 'WARNING: Running on Jetson Nano with onnxruntime-gpu 1.11.0 instead of required 1.17.0+'" >> /usr/local/bin/jetson-nano-warning.sh && \
    echo "echo 'Some ML features may not work as expected. This is a compatibility build.'" >> /usr/local/bin/jetson-nano-warning.sh && \
    chmod +x /usr/local/bin/jetson-nano-warning.sh


ARG BUILD_ID
ARG BUILD_IMAGE
ARG BUILD_SOURCE_REF
ARG BUILD_SOURCE_COMMIT

ENV IMMICH_BUILD=${BUILD_ID}
ENV IMMICH_BUILD_URL=https://github.com/immich-app/immich/actions/runs/${BUILD_ID}
ENV IMMICH_BUILD_IMAGE=${BUILD_IMAGE}
ENV IMMICH_BUILD_IMAGE_URL=https://github.com/immich-app/immich/pkgs/container/immich-machine-learning
ENV IMMICH_REPOSITORY=immich-app/immich
ENV IMMICH_REPOSITORY_URL=https://github.com/immich-app/immich
ENV IMMICH_SOURCE_REF=${BUILD_SOURCE_REF}
ENV IMMICH_SOURCE_COMMIT=${BUILD_SOURCE_COMMIT}
ENV IMMICH_SOURCE_URL=https://github.com/immich-app/immich/commit/${BUILD_SOURCE_COMMIT}

ENTRYPOINT ["tini", "--"]
CMD ["/bin/bash", "-c", "/usr/local/bin/jetson-nano-warning.sh && python -m immich_ml"]

HEALTHCHECK CMD python3 healthcheck.py
