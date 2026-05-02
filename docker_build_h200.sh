#!/bin/bash
# Build cuOpt Docker image from source for H200 deployment
# Run this script from the cuopt repo root: bash docker_build_h200.sh
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-cuopt-h200}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CUDA_VER="${CUDA_VER:-12.9.0}"
# Limit parallel jobs to avoid OOM; 0 = auto (uses all cores)
PARALLEL_LEVEL="${PARALLEL_LEVEL:-8}"

echo "=== cuOpt H200 Docker Build ==="
echo "Image      : ${IMAGE_NAME}:${IMAGE_TAG}"
echo "CUDA       : ${CUDA_VER}"
echo "Parallel   : ${PARALLEL_LEVEL}"
echo ""
echo "Expected build time: 30-60 min (first time, downloads ~8 GB of conda packages)"
echo ""

docker build \
    -f Dockerfile.build \
    --build-arg CUDA_VER="${CUDA_VER}" \
    --build-arg PARALLEL_LEVEL="${PARALLEL_LEVEL}" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    --progress=plain \
    .

echo ""
echo "=== Build complete ==="
echo "Smoke test:"
docker run --rm --gpus all "${IMAGE_NAME}:${IMAGE_TAG}" \
    python -c "import cuopt; print('cuopt version:', cuopt.__version__)"

echo ""
echo "To save and transfer to H200:"
echo "  docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > cuopt-h200.tar.gz"
echo "  # On H200: docker load < cuopt-h200.tar.gz"
echo "  # On H200: docker run --gpus all -it ${IMAGE_NAME}:${IMAGE_TAG}"
