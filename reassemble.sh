#!/bin/bash
# reassemble.sh — 在公司（離線）環境組合 Docker image chunks
#
# 用法：
#   bash reassemble.sh <chunk前綴> <tag> <suffix列表>
#
# 範例：
#   bash reassemble.sh cuopt-full 26.6 aa ab ac ad ae af ag ah ai aj
#   bash reassemble.sh cuopt-allinone 26.6 aa ab ac ad ae af ag ah ai

set -e

NAME=${1:?"用法: bash reassemble.sh <name> <tag> <suffix1> <suffix2> ..."}
TAG=${2:?"用法: bash reassemble.sh <name> <tag> <suffix1> <suffix2> ..."}
shift 2
SUFFIXES=("$@")

if [ ${#SUFFIXES[@]} -eq 0 ]; then
    echo "錯誤：請提供 suffix 列表（e.g. aa ab ac）"
    exit 1
fi

echo "========================================"
echo "組合 workcc/${NAME}:${TAG}"
echo "Chunks: ${#SUFFIXES[@]} 個 (${SUFFIXES[*]})"
echo "========================================"
echo ""

# Step 1: Pull
echo "=== Step 1: Pull chunk images ==="
for s in "${SUFFIXES[@]}"; do
    echo "  Pulling workcc/${NAME}-part-${s}:${TAG}..."
    docker pull "workcc/${NAME}-part-${s}:${TAG}"
done

# Step 2: Extract
echo ""
echo "=== Step 2: 解出 chunk 檔案 ==="
PARTS=()
for s in "${SUFFIXES[@]}"; do
    echo -n "  Extracting part_${s}... "
    docker run --rm "workcc/${NAME}-part-${s}:${TAG}" > "part_${s}"
    echo "$(du -sh part_${s} | cut -f1)"
    PARTS+=("part_${s}")
done

# Step 3: Combine + load
echo ""
echo "=== Step 3: 組合並載入 ==="
echo "  cat ${PARTS[*]} | docker load"
cat "${PARTS[@]}" | docker load

# Step 4: Verify
echo ""
echo "=== Step 4: 確認 ==="
docker images | grep "${NAME}" | grep -v "\-part\-"

# Step 5: Cleanup
echo ""
echo "=== Step 5: 清除暫存檔 ==="
rm -f "${PARTS[@]}"
echo "  清除完成"
echo ""
echo "完成！現在可以執行："
echo "  docker run --gpus all --rm workcc/${NAME}:${TAG}"
