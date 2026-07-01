#!/bin/bash
# ============================================================
# V1 任务运行脚本 — 对应讲稿第 10 课时
#
# 功能：运行 V1c1 任务（按小时统计平均电压和电流）
#
# 使用方法：
#   bash scripts/run_v1c1.sh
# ============================================================

set -e

# 自动定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

JAR_FILE="target/Enge1relase.jar"
HDFS_OUTPUT="/Car/v1"
CLASS_NAME="com.neu.datapro.V1c1"

echo "=============================================="
echo "  运行 V1c1 — 按小时平均电压/电流"
echo "=============================================="
echo ""

# 1. 检查 JAR 文件
if [ ! -f "$JAR_FILE" ]; then
    echo "ERROR: 找不到 $JAR_FILE"
    echo "请先运行编译脚本: bash scripts/compile.sh"
    exit 1
fi

# 2. 删除旧的 HDFS 输出
echo ">>> 删除旧 HDFS 输出: $HDFS_OUTPUT"
hdfs dfs -rm -r -f "$HDFS_OUTPUT" 2>/dev/null || true
echo ""

# 3. 运行任务
echo ">>> 提交 MapReduce 作业: $CLASS_NAME"
echo ""
HADOOP_CLASSPATH=lib/mysql-connector.jar \
hadoop jar "$JAR_FILE" "$CLASS_NAME"

EXIT_CODE=$?
echo ""

# 4. 显示结果
if [ $EXIT_CODE -eq 0 ]; then
    echo "=============================================="
    echo "  V1c1 运行成功！"
    echo "=============================================="
    echo ""
    echo "--- HDFS 输出 ($HDFS_OUTPUT) ---"
    hdfs dfs -cat "$HDFS_OUTPUT/part-r-00000" 2>/dev/null || \
        hdfs dfs -cat "$HDFS_OUTPUT/part-"* 2>/dev/null
    echo ""
    echo "--- MySQL 输出 ---"
    mysql -u bi -pbi123456 -e "SELECT * FROM enger.t_enger1;" 2>/dev/null || \
        echo "（无法连接 MySQL，请手动验证: SELECT * FROM enger.t_enger1;）"
else
    echo "ERROR: V1c1 运行失败，退出码: $EXIT_CODE"
    echo "请检查上方日志排查问题。"
    exit $EXIT_CODE
fi
