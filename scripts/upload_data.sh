#!/bin/bash
# ============================================================
# HDFS 数据上传脚本 — 对应讲稿第 6 课时
#
# 功能：将本地 CSV 数据文件上传到 HDFS /Car/ 目录
#
# 使用方法：
#   bash scripts/upload_data.sh
# ============================================================

set -e

# 自动定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

HDFS_DIR="/Car"
HDFS_FILE="/Car/dsv13r1.csv"
LOCAL_FILE="data/dsv13r1.csv"

echo "=============================================="
echo "  上传数据到 HDFS"
echo "=============================================="
echo ""

# 1. 检查 Hadoop 是否运行
echo ">>> 步骤 1/4: 检查 Hadoop 环境..."
if ! command -v hdfs &> /dev/null; then
    echo "ERROR: 找不到 hdfs 命令，请确认 Hadoop 已安装并配置 PATH。"
    exit 1
fi

if ! hdfs dfs -ls / &> /dev/null; then
    echo "ERROR: HDFS 无法访问，请确认 Hadoop 已启动（start-dfs.sh）。"
    exit 1
fi
echo "    Hadoop 环境正常"
echo ""

# 2. 检查本地数据文件
echo ">>> 步骤 2/4: 检查本地数据文件..."
if [ ! -f "$LOCAL_FILE" ]; then
    echo "ERROR: 找不到数据文件 $LOCAL_FILE"
    echo "请将 dsv13r1.csv 放到项目的 data/ 目录下。"
    exit 1
fi
echo "    本地文件: $LOCAL_FILE ($(ls -lh "$LOCAL_FILE" | awk '{print $5}'))"
echo ""

# 3. 创建 HDFS 目录
echo ">>> 步骤 3/4: 创建 HDFS 目录..."
hdfs dfs -mkdir -p "$HDFS_DIR"
echo "    HDFS 目录: $HDFS_DIR"
echo ""

# 4. 上传文件
echo ">>> 步骤 4/4: 上传数据文件..."
hdfs dfs -put -f "$LOCAL_FILE" "$HDFS_FILE"
echo "    上传完成"
echo ""

# 验证
echo "=============================================="
echo "  上传完成！验证 HDFS 文件："
echo "=============================================="
hdfs dfs -ls "$HDFS_FILE"
echo ""
echo "文件行数:"
hdfs dfs -cat "$HDFS_FILE" | wc -l
