#!/bin/bash
# Build cuOpt from source inside Docker.
# Called by Dockerfile.build — avoids cmake-args quoting issues in RUN strings.
set -eo pipefail

# conda env 存在時啟動（conda build），否則為官方 image 環境（pip build）
if [ -f /opt/conda/etc/profile.d/conda.sh ]; then
    source /opt/conda/etc/profile.d/conda.sh
    conda activate /opt/cuopt_env
fi

# 官方 image 環境：把 RAPIDS_DIST 下的 cmake 路徑轉成 cmake 分號分隔格式
if [ -n "${RAPIDS_DIST:-}" ]; then
    # CUDA stubs 讓 cmake 找到 CUDA::cublas 等 targets 而不需要安裝完整的 -dev 套件
    # 實際執行時 libcublas 由 cuopt pip packages 的 .libs 目錄提供
    export CMAKE_LIBRARY_PATH="/usr/local/cuda/targets/x86_64-linux/lib/stubs:${CMAKE_LIBRARY_PATH:-}"

    # cmake 從 env var 讀 CMAKE_PREFIX_PATH 時使用 Unix PATH 格式（冒號分隔）
    export CMAKE_PREFIX_PATH="\
${RAPIDS_DIST}/libcuopt/lib64/rapids/cmake:\
${RAPIDS_DIST}/libraft/lib64/rapids/cmake:\
${RAPIDS_DIST}/librmm/lib64/rapids/cmake:\
${RAPIDS_DIST}/libcudf/lib64/rapids/cmake:\
${RAPIDS_DIST}/libcuopt/lib64/cmake:\
${RAPIDS_DIST}/libraft/lib64/cmake:\
${RAPIDS_DIST}/librmm/lib64/cmake:\
${RAPIDS_DIST}/libcudf/lib64/cmake:\
${RAPIDS_DIST}/libkvikio/lib64/cmake:\
${RAPIDS_DIST}/rapids_logger/lib64/cmake:\
${RAPIDS_DIST}/libcuopt/lib64:\
${RAPIDS_DIST}/libraft/lib64:\
${RAPIDS_DIST}/librmm/lib64:\
${RAPIDS_DIST}"
    echo "CMAKE_PREFIX_PATH set for official image environment"
fi

# 預先 clone 的 FetchContent 依賴（離線 build 用）
export FETCHCONTENT_SOURCE_DIR_PAPILO="${FETCHCONTENT_SOURCE_DIR_PAPILO:-/opt/cuopt-deps/papilo}"
export FETCHCONTENT_SOURCE_DIR_PSLP="${FETCHCONTENT_SOURCE_DIR_PSLP:-/opt/cuopt-deps/pslp}"
export FETCHCONTENT_SOURCE_DIR_ARGPARSE="${FETCHCONTENT_SOURCE_DIR_ARGPARSE:-/opt/cuopt-deps/argparse}"

export CUDACXX="$(which nvcc)"
export PARALLEL_LEVEL="${PARALLEL_LEVEL:-1}"

echo "=== cuOpt build ==="
echo "CUDACXX        : ${CUDACXX}"
echo "PARALLEL_LEVEL : ${PARALLEL_LEVEL}"
echo ""

# CUOPT_BUILD_ARCHS 控制編譯的 GPU 架構：
#   未設定（預設）→ NATIVE：docker run --gpus all 時自動偵測本機 GPU（最快）
#   "deploy"     → RAPIDS：所有架構（sm_70~sm_120），部署用，--allgpuarch
# Dockerfile.build 設定 CUOPT_BUILD_ARCHS=deploy 以取得完整架構支援
if [ "${CUOPT_BUILD_ARCHS:-native}" = "deploy" ]; then
    echo "CUDA 架構 : RAPIDS 全架構（sm_70/75/80/86/90a/100f/120a/120）"
    ARCH_FLAG="--allgpuarch"
else
    echo "CUDA 架構 : NATIVE（自動偵測本機 GPU，dev 容器最快）"
    ARCH_FLAG=""
fi
echo ""

# 官方 image 環境需要 --no-fetch-rapids（rapids-cmake 已在 image 中）
# 和 --skip-grpc-build（gRPC 離線無法下載）
if [ -n "${RAPIDS_DIST:-}" ]; then
    EXTRA_FLAGS="--no-fetch-rapids --skip-grpc-build"
else
    EXTRA_FLAGS=""
fi

./build.sh ${ARCH_FLAG} ${EXTRA_FLAGS} --skip-tests-build "$@"
