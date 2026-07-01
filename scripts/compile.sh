#!/bin/bash
# ============================================================
# 编译打包脚本 — 对应讲稿第 10 课时
#
# 功能：清理旧的编译文件，编译全部 7 个 MapReduce 任务，
#       打包为 target/Enge1relase.jar
#
# 使用方法：
#   bash scripts/compile.sh
# ============================================================

set -e

# 自动定位项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "=============================================="
echo "  编译打包 MapReduce 项目"
echo "  项目目录: $PROJECT_DIR"
echo "=============================================="
echo ""

# 1. 清理旧文件
echo ">>> 步骤 1/3: 清理旧的编译文件..."
rm -rf target/classes target/Enge1relase.jar
mkdir -p target/classes
echo "    清理完成"
echo ""

# 2. 编译
echo ">>> 步骤 2/3: 编译 Java 源码..."
javac -encoding UTF-8 -source 1.7 -target 1.7 \
    -classpath "$(hadoop classpath):lib/mysql-connector.jar" \
    -d target/classes \
    $(find src/main/java -name "*.java")

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: 编译失败！请检查上方错误信息。"
    exit 1
fi
echo "    编译成功！"
echo ""

# 3. 打包
echo ">>> 步骤 3/3: 打包 JAR..."
jar cf target/Enge1relase.jar -C target/classes .

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: 打包失败！"
    exit 1
fi

echo "    打包完成！"
echo ""

# 验证
echo "=============================================="
echo "  编译打包完成！"
echo "  JAR 文件: target/Enge1relase.jar"
echo "  文件大小: $(ls -lh target/Enge1relase.jar | awk '{print $5}')"
echo "=============================================="
echo ""
echo "JAR 包内容:"
jar tf target/Enge1relase.jar | grep -E "V[0-9].*\.class$" | sort
