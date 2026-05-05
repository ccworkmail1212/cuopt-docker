# 離線環境組合 Docker Image 指南

公司內網無法直接 pull 大型 Docker image，
本指南說明如何從分塊的 chunk images 還原完整 image。

---

## 前置條件

- 公司電腦已安裝 Docker
- 已確認 Docker daemon 正常運行：`docker info`

---

## 可用的 Images

| 完整 Image | Chunk 前綴 | Chunk 數量 | 還原後大小 |
|---|---|---|---|
| `workcc/cuopt-full:26.6` | `cuopt-full-part-XX` | 10 個 | ~9.5GB |
| `workcc/cuopt-allinone:26.6` | `cuopt-allinone-part-XX` | 9 個 | ~8.6GB |

---

## 方法一：使用腳本（建議）

```bash
# 1. 取得腳本
git clone https://github.com/ccworkmail1212/cuopt-docker.git
cd cuopt-docker

# 2. 組合 cuopt-full
bash reassemble.sh cuopt-full 26.6 aa ab ac ad ae af ag ah ai aj

# 3. 組合 cuopt-allinone（選用）
bash reassemble.sh cuopt-allinone 26.6 aa ab ac ad ae af ag ah ai
```

腳本會自動完成所有步驟，完成後顯示可用的 image。

---

## 方法二：手動逐步操作

### 以 `workcc/cuopt-full:26.6` 為例

#### Step 1：Pull 所有 chunk images

```bash
docker pull workcc/cuopt-full-part-aa:26.6
docker pull workcc/cuopt-full-part-ab:26.6
docker pull workcc/cuopt-full-part-ac:26.6
docker pull workcc/cuopt-full-part-ad:26.6
docker pull workcc/cuopt-full-part-ae:26.6
docker pull workcc/cuopt-full-part-af:26.6
docker pull workcc/cuopt-full-part-ag:26.6
docker pull workcc/cuopt-full-part-ah:26.6
docker pull workcc/cuopt-full-part-ai:26.6
docker pull workcc/cuopt-full-part-aj:26.6
```

> 每個 chunk 約 500MB，共約 5GB，請確保磁碟有足夠空間（建議 20GB+）。

#### Step 2：從 chunk image 解出檔案

每個 chunk image 執行時會直接輸出 chunk 內容（`cat /chunk`），用 `>` 存到檔案：

```bash
docker run --rm workcc/cuopt-full-part-aa:26.6 > part_aa
docker run --rm workcc/cuopt-full-part-ab:26.6 > part_ab
docker run --rm workcc/cuopt-full-part-ac:26.6 > part_ac
docker run --rm workcc/cuopt-full-part-ad:26.6 > part_ad
docker run --rm workcc/cuopt-full-part-ae:26.6 > part_ae
docker run --rm workcc/cuopt-full-part-af:26.6 > part_af
docker run --rm workcc/cuopt-full-part-ag:26.6 > part_ag
docker run --rm workcc/cuopt-full-part-ah:26.6 > part_ah
docker run --rm workcc/cuopt-full-part-ai:26.6 > part_ai
docker run --rm workcc/cuopt-full-part-aj:26.6 > part_aj
```

確認每個 part 約 500MB：

```bash
ls -lh part_*
```

#### Step 3：組合並載入

將所有 chunk 依序合併，解壓後直接 pipe 給 `docker load`：

```bash
cat part_aa part_ab part_ac part_ad part_ae \
    part_af part_ag part_ah part_ai part_aj \
    | docker load
```

> 這個步驟需要約 10-20 分鐘（需要解壓 4.7GB 並載入 Docker）。

#### Step 4：確認

```bash
docker images | grep cuopt-full
```

應看到：
```
workcc/cuopt-full   26.6   xxxxxxxxx   ...   9.56GB
```

#### Step 5：清除暫存檔

```bash
rm part_aa part_ab part_ac part_ad part_ae \
   part_af part_ag part_ah part_ai part_aj
```

---

## 組合 cuopt-allinone（9 個 chunks）

同上流程，suffix 為 `aa ~ ai`：

```bash
# Pull
for s in aa ab ac ad ae af ag ah ai; do
    docker pull workcc/cuopt-allinone-part-${s}:26.6
done

# Extract
for s in aa ab ac ad ae af ag ah ai; do
    docker run --rm workcc/cuopt-allinone-part-${s}:26.6 > part_${s}
done

# Load
cat part_aa part_ab part_ac part_ad part_ae \
    part_af part_ag part_ah part_ai | docker load

# Cleanup
rm part_aa part_ab part_ac part_ad part_ae part_af part_ag part_ah part_ai
```

---

## 取得完整 image 後的使用方式

```bash
# 跑 lot scheduling demo（不需掛任何 volume）
docker run --gpus all --rm workcc/cuopt-full:26.6

# 互動模式
docker run --gpus all --rm -it workcc/cuopt-full:26.6 bash

# 掛入自己的腳本
docker run --gpus all --rm \
    -v ~/my_scripts:/workspace \
    --workdir /workspace \
    workcc/cuopt-full:26.6 \
    python3 my_script.py
```

---

## 常見問題

**Q：Step 3 的 `docker load` 跑很久正常嗎？**
A：正常。解壓 4.7GB 並建立 image layer 需要 10-20 分鐘。

**Q：Step 2 執行後 part_XX 檔案是空的怎麼辦？**
A：確認 `docker run` 有正常執行（容器應立即退出並輸出內容），
   重新執行該 chunk 的 `docker run > part_XX`。

**Q：`docker load` 後沒看到 image？**
A：確認 cat 的順序是 aa → aj（不能亂序），重新執行 Step 3。

**Q：chunk image 每個多大？**
A：Docker Hub 顯示約 500MB（壓縮後），pull 後解壓約 500MB。

---

## Repositories

- Docker Hub chunks：https://hub.docker.com/u/workcc
- 腳本來源：https://github.com/ccworkmail1212/cuopt-docker
