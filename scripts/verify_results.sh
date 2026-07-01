#!/bin/bash
# ============================================================
# 结果验证脚本 — 对应讲稿第 13 课时
#
# 功能：检查所有 7 个 HDFS 输出目录和 MySQL 表的数据
#
# 使用方法：
#   bash scripts/verify_results.sh
# ============================================================

# 自动定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "=============================================="
echo "  验证 MapReduce 运行结果"
echo "=============================================="
echo ""

# ---- HDFS 验证 ----
echo "=============================================="
echo "  一、HDFS 输出验证"
echo "=============================================="
echo ""

ALL_HDFS_OK=true

for i in 1 2 3 4 5 6 7; do
    OUTPUT_DIR="/Car/v$i"

    printf "  v%d ... " "$i"

    # 检查目录是否存在
    if ! hdfs dfs -test -d "$OUTPUT_DIR" 2>/dev/null; then
        echo "✗ 目录不存在 ($OUTPUT_DIR)"
        ALL_HDFS_OK=false
        continue
    fi

    # 检查 _SUCCESS 文件
    if hdfs dfs -test -f "$OUTPUT_DIR/_SUCCESS" 2>/dev/null; then
        echo -n "✓ _SUCCESS "
    else
        echo -n "✗ 缺少_SUCCESS "
        ALL_HDFS_OK=false
    fi

    # 显示前 2 行数据
    DATA=$(hdfs dfs -cat "$OUTPUT_DIR/part-r-00000" 2>/dev/null | head -2)
    if [ -n "$DATA" ]; then
        echo "| 样例: $DATA"
    else
        echo "| (无数据)"
        ALL_HDFS_OK=false
    fi
done

echo ""

# ---- MySQL 验证 ----
echo "=============================================="
echo "  二、MySQL 数据验证"
echo "=============================================="
echo ""

ALL_MYSQL_OK=true

for i in 1 2 3 4 5 6 7; do
    TABLE="t_enger$i"

    printf "  %s ... " "$TABLE"

    COUNT=$(mysql -u bi -pbi123456 -N -e "SELECT COUNT(*) FROM enger.$TABLE;" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$COUNT" ]; then
        if [ "$COUNT" -gt 0 ]; then
            echo "✓ $COUNT 行"
        else
            echo "⚠ 0 行（表存在但无数据）"
            ALL_MYSQL_OK=false
        fi
    else
        echo "✗ 无法连接或表不存在"
        ALL_MYSQL_OK=false
    fi
done

echo ""

# ---- 汇总 ----
echo "=============================================="
echo "  验证汇总"
echo "=============================================="
echo ""

if [ "$ALL_HDFS_OK" = true ]; then
    echo "  HDFS:  ✓ 全部 7 个输出目录正常"
else
    echo "  HDFS:  ✗ 部分输出目录异常，请检查"
fi

if [ "$ALL_MYSQL_OK" = true ]; then
    echo "  MySQL: ✓ 全部 7 张表有数据"
else
    echo "  MySQL: ✗ 部分表异常，请检查"
fi

echo ""

# ---- 详细样例 ----
echo "=============================================="
echo "  三、各任务输出样例"
echo "=============================================="
echo ""

for i in 1 2 3 4 5 6 7; do
    OUTPUT_DIR="/Car/v$i"
    echo "--- v$i ($OUTPUT_DIR) ---"
    hdfs dfs -cat "$OUTPUT_DIR/part-r-00000" 2>/dev/null | head -5
    echo ""
done

echo "=============================================="
echo "  验证完成"
echo "=============================================="
