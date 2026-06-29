# Car-Charge-Tracker

电动车充电数据 MapReduce 分析 — 按小时统计平均电池包电压和充电电流。

## 技术栈

- **Hadoop** 2.6.5 — MapReduce 计算框架
- **MySQL** — 结果持久化存储
- **Java** 1.8 — 开发语言

## 项目结构

```
├── data/
│   └── dsv13r1.csv           # 示例输入数据
├── src/main/java/com/neu/datapro/
│   └── V1c1.java             # 主程序（Mapper + Reducer + Driver）
├── lib/
│   └── mysql-connector.jar   # MySQL JDBC 驱动
├── pom.xml
├── run_on_vm.sh              # 一键运行（含截图提示）
├── run_v1c1.sh               # 快速运行脚本
└── .gitignore
```

## 数据说明

`dsv13r1.csv` 字段：

| 序号 | 字段 | 说明 |
|------|------|------|
| 0 | index | 序号 |
| 1 | time | 时间戳 (yyyyMMddHHmmss) |
| 2 | SOC | 电池电量 |
| 3 | pack_voltage | 电池包电压 (V) |
| 4 | charge_current | 充电电流 (A) |
| 5 | max_cell_voltage | 最高单体电压 |
| 6 | min_cell_voltage | 最低单体电压 |
| 7 | max_temp | 最高温度 |
| 8 | min_temp | 最低温度 |
| 9 | energy | 能量 |
| 10 | capacity | 容量 |

## 快速开始

```bash
# 1. 启动 Hadoop
start-dfs.sh && start-yarn.sh

# 2. 上传数据到 HDFS
hdfs dfs -mkdir -p /Car
hdfs dfs -put data/dsv13r1.csv /Car/

# 3. 编译打包
cd ~/project/car-charge-tracker
javac -encoding UTF-8 -source 1.7 -target 1.7 \
    -classpath "$(hadoop classpath):lib/mysql-connector.jar" \
    -d target/classes $(find src/main/java -name "*.java")
jar cf target/car-charge-tracker.jar -C target/classes .

# 4. 运行
HADOOP_CLASSPATH=lib/mysql-connector.jar \
hadoop jar target/car-charge-tracker.jar com.neu.datapro.V1c1
```

或使用脚本：

```bash
./run_v1c1.sh
```

## 输出

### HDFS (`/Car/v1/part-r-00000`)

| 小时 | 平均电压 (V) | 平均电流 (A) |
|------|-------------|-------------|
| 00 | 327.89 | -73.73 |
| 11 | 326.73 | -22.5 |
| 12 | 330.95 | -22.5 |
| 13 | 340.08 | -22.5 |
| 14 | 352.79 | -22.5 |

### MySQL (`enger.t_enger1`)

| record_time | avg_pack_voltage | avg_charge_current |
|-------------|-----------------|-------------------|
| 00 | 327.8875 | -73.7250125 |
| 11 | 326.72776025236567 | -22.5 |
| 12 | 330.94866666666707 | -22.5 |
| 13 | 340.07800000000015 | -22.5 |
| 14 | 352.7929539295395 | -22.5 |
