# cuOpt Docker Tools

NVIDIA cuOpt 26.06 Docker 建置與開發環境工具。

## Docker Hub Images

| Image | 說明 |
|-------|------|
| `workcc/cuopt-custom:26.6.0a` | 執行環境（~740MB delta，基於官方 nvidia/cuopt） |
| `workcc/cuopt-src:26.6` | cuOpt 原始碼（336MB） |

## 快速開始

### 1. Pull Images

```bash
docker pull nvidia/cuopt:26.6.0a-cuda12.9-py3.14   # 官方 base
docker pull workcc/cuopt-custom:26.6.0a
docker pull workcc/cuopt-src:26.6
```

### 2. 取出 Source Code

```bash
docker run --rm workcc/cuopt-src:26.6 \
    tar cf - /cuopt | tar xf - -C /workspace/
```

### 3. 啟動開發環境

```bash
bash run_dev.sh
```

容器內指令：

```bash
cuopt-build                          # 完整 build
cuopt-build --cache-tool=ccache      # 加速 rebuild
ctest --test-dir cpp/build -j4       # C++ 測試
pytest python/cuopt/cuopt/tests -v   # Python 測試
```

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `Dockerfile.build` | 從原始碼完整編譯 cuOpt（conda 方式） |
| `Dockerfile.dev-official` | 開發容器（基於官方 nvidia/cuopt） |
| `Dockerfile.src` | 打包 source code 的 image |
| `Dockerfile.package` | 送審用的 < 2GB image |
| `run_dev.sh` | 一鍵啟動開發容器 |
| `docker_build_h200.sh` | 建立 H200 部署 image |
| `ci/docker/build_cuopt.sh` | 容器內 build 包裝腳本 |

## 系統需求

- NVIDIA GPU（Volta 架構以上，compute capability ≥ 7.0）
- Docker + nvidia-container-toolkit
- CUDA 12.9+
