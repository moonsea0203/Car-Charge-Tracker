#!/bin/bash
# ============================================================
# 通用单任务运行器 — 对应讲稿第 11-12 课时
#
# 功能：接受类名参数，运行任意单个 MapReduce 任务
#
# 使用方法：
#   bash scripts/run_single.sh V1c1
#   bash scripts/run_single.sh V2c1
#   bash scripts/run_single.sh V3_timeTempMinMax
#   ...
# ============================================================

set -e

# 自动定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

JAR_FILE="target/Enge1relase.jar"

# 类名 → HDFS 输出目录 映射
declare -A OUTPUT_DIRS=(
    ["V1c1"]="/Car/v1"
    ["V2c1"]="/Car/v2"
    ["V3_timeTempMinMax"]="/Car/v3"
    ["V4_Ava_Ene_Cap"]="/Car/v4"
    ["V5_chargeCurrent"]="/Car/v5"
    ["V6_VA"]="/Car/v6"
    ["V7_battryStatusAvg"]="/Car/v7"
)

# 类名 → 任务描述
declare -A TASK_DESC=(
    ["V1c1"]="按小时平均电压/电流"
    ["V2c1"]="电芯电压极值"
    ["V3_timeTempMinMax"]="温度极值"
    ["V4_Ava_Ene_Cap"]="能量与容量"
    ["V5_chargeCurrent"]="充电电流统计"
    ["V6_VA"]="电压电流变化率"
    ["V7_battryStatusAvg"]="电池状态温度"
)

print_usage() {
    echo "使用方法: bash scripts/run_single.sh <类名>"
    echo ""
    echo "可用的类名："
    for cls in V1c1 V2c1 V3_timeTempMinMax V4_Ava_Ene_Cap V5_chargeCurrent V6_VA V7_battryStatusAvg; do
        printf "  %-22s → %-10s %s\n" "$cls" "${OUTPUT_DIRS[$cls]}" "${TASK_DESC[$cls]}"
    done
    exit 1
}

# 检查参数
CLASS_NAME="$1"
if [ -z "$CLASS_NAME" ]; then
    echo "ERROR: 请指定要运行的类名。"
    echo ""
    print_usage
fi

OUTPUT_DIR="${OUTPUT_DIRS[$CLASS_NAME]}"
if [ -z "$OUTPUT_DIR" ]; then
    echo "ERROR: 未知的类名 '$CLASS_NAME'"
    echo ""
    print_usage
fi

DESC="${TASK_DESC[$CLASS_NAME]}"

# 检查 JAR 文件
if [ ! -f "$JAR_FILE" ]; then
    echo "ERROR: 找不到 $JAR_FILE"
    echo "请先运行编译脚本: bash scripts/compile.sh"
    exit 1
fi

echo "=============================================="
echo "  运行 $CLASS_NAME — $DESC"
echo "=============================================="
echo ""

# 删除旧 HDFS 输出
echo ">>> 删除旧 HDFS 输出: $OUTPUT_DIR"
hdfs dfs -rm -r -f "$OUTPUT_DIR" 2>/dev/null || true
echo ""

# 运行任务
echo ">>> 提交 MapReduce 作业..."
echo ""
HADOOP_CLASSPATH=lib/mysql-connector.jar \
hadoop jar "$JAR_FILE" "com.neu.datapro.$CLASS_NAME"

EXIT_CODE=$?
echo ""

# 显示结果
if [ $EXIT_CODE -eq 0 ]; then
    echo "=============================================="
    echo "  $CLASS_NAME 运行成功！"
    echo "=============================================="
    echo ""
    echo "--- HDFS 输出 ($OUTPUT_DIR) ---"
    hdfs dfs -cat "$OUTPUT_DIR/part-r-00000" 2>/dev/null || \
        hdfs dfs -cat "$OUTPUT_DIR/part-"* 2>/dev/null
else
    echo "ERROR: $CLASS_NAME 运行失败，退出码: $EXIT_CODE"
    echo "请检查上方日志排查问题。"
    exit $EXIT_CODE
fi
