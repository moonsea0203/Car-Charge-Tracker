#!/bin/bash
# ============================================================
# 全部任务批量运行脚本 — 对应讲稿第 13 课时
#
# 功能：依次运行 V1c1 到 V7_battryStatusAvg 共 7 个任务
#
# 使用方法：
#   bash scripts/run_all.sh
# ============================================================

set -e

# 自动定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

JAR_FILE="target/Enge1relase.jar"

# 任务列表（按顺序），V1~V7
TASKS=(
    "V1c1"
    "V2c1"
    "V3_timeTempMinMax"
    "V4_Ava_Ene_Cap"
    "V5_chargeCurrent"
    "V6_VA"
    "V7_battryStatusAvg"
)

# 类名 → HDFS 输出目录
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

# 检查 JAR
if [ ! -f "$JAR_FILE" ]; then
    echo "ERROR: 找不到 $JAR_FILE"
    echo "请先运行编译脚本: bash scripts/compile.sh"
    exit 1
fi

echo "=============================================="
echo "  批量运行全部 V1 ~ V7 任务"
echo "  共 ${#TASKS[@]} 个任务"
echo "=============================================="
echo ""

START_TIME=$(date +%s)
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_TASKS=""

for cls in "${TASKS[@]}"; do
    OUTPUT_DIR="${OUTPUT_DIRS[$cls]}"
    DESC="${TASK_DESC[$cls]}"

    echo "=============================================="
    echo "  >>> [$((SUCCESS_COUNT + FAIL_COUNT + 1))/${#TASKS[@]}] $cls — $DESC"
    echo "=============================================="
    echo ""

    # 删除旧输出
    hdfs dfs -rm -r -f "$OUTPUT_DIR" 2>/dev/null || true

    # 运行
    HADOOP_CLASSPATH=lib/mysql-connector.jar \
    hadoop jar "$JAR_FILE" "com.neu.datapro.$cls"

    if [ $? -eq 0 ]; then
        echo ""
        echo "  ✓ $cls 运行成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo ""
        echo "  ✗ $cls 运行失败！"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_TASKS="$FAILED_TASKS $cls"
    fi
    echo ""
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 汇总
echo "=============================================="
echo "  全部任务运行完成"
echo "=============================================="
echo "  总任务数: ${#TASKS[@]}"
echo "  成功:     $SUCCESS_COUNT"
echo "  失败:     $FAIL_COUNT"
echo "  总耗时:   ${DURATION}s"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo "  失败的任务:$FAILED_TASKS"
    echo ""
    echo "  请检查这些任务的日志，排查问题后重新运行。"
    exit 1
fi

echo "  全部 V1~V7 任务均运行成功！🎉"
echo ""
echo "  运行验证脚本查看结果: bash scripts/verify_results.sh"
