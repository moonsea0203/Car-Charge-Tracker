# Enge1relase

电动车充电数据 MapReduce 分析 — 7 个任务，覆盖电压、电流、温度、能量等多维度统计。

## 技术栈

- **Hadoop** 2.6.5 — MapReduce 计算框架
- **MySQL** — 结果持久化存储
- **Java** 1.8 — 开发语言

## 项目结构

```
├── data/
│   └── dsv13r1.csv                    # 示例输入数据
├── src/main/java/com/neu/datapro/
│   ├── V1c1.java                      # 任务1: 按小时平均电压/电流
│   ├── V2c1.java                      # 任务2: 按小时电压极值
│   ├── V3_timeTempMinMax.java         # 任务3: 按小时温度极值
│   ├── V4_Ava_Ene_Cap.java            # 任务4: 按小时能量/容量
│   ├── V5_chargeCurrent.java          # 任务5: 按小时充电电流统计
│   ├── V6_VA.java                     # 任务6: 按小时电压/电流变化率
│   └── V7_battryStatusAvg.java       # 任务7: 按电池状态温度统计
├── lib/
│   └── mysql-connector.jar            # MySQL JDBC 驱动
├── db.properties.example              # 数据库配置模板
├── pom.xml
├── run_v1c1.sh
└── .gitignore
```

## 任务总览

| # | 类名 | 分组 | 聚合 | MySQL 表 | HDFS 输出 |
|---|------|------|------|----------|-----------|
| 1 | `V1c1` | 小时 | avg(电压), avg(电流) | `t_enger1` | `/Car/v1` |
| 2 | `V2c1` | 小时 | max(电压), min(电压) | `t_enger2` | `/Car/v2` |
| 3 | `V3_timeTempMinMax` | 小时 | max(最高温), min(最低温) | `t_enger3` | `/Car/v3` |
| 4 | `V4_Ava_Ene_Cap` | 小时 | avg(能量), avg(容量) | `t_enger4` | `/Car/v4` |
| 5 | `V5_chargeCurrent` | 小时 | avg(电流), max(电流) | `t_enger5` | `/Car/v5` |
| 6 | `V6_VA` | 小时 | avg(电压), avg(电流) | `t_enger6` | `/Car/v6` |
| 7 | `V7_battryStatusAvg` | SOC 三级* | avg(最高温), avg(最低温) | `t_enger7` | `/Car/v7` |

> \* SOC 三级: low(<30), medium(30-70), high(>70)

## 数据说明

`dsv13r1.csv` 共 11 列：

| 索引 | 字段 | 说明 | 示例 |
|------|------|------|------|
| 0 | index | 序号 | 0 |
| 1 | time | 时间戳 (yyyyMMddHHmmss) | 20190726111742 |
| 2 | SOC | 电池电量 (%) | 15.2 |
| 3 | pack_voltage | 电池包电压 (V) | 323.5 |
| 4 | charge_current | 充电电流 (A) | -22.5 |
| 5 | max_cell_voltage | 最高单体电压 (V) | 3.603 |
| 6 | min_cell_voltage | 最低单体电压 (V) | 3.584 |
| 7 | max_temp | 最高温度 (°C) | 32 |
| 8 | min_temp | 最低温度 (°C) | 31 |
| 9 | energy | 能量 | 6.96 |
| 10 | capacity | 容量 | 20.94 |

## 快速开始

```bash
# 1. 启动 Hadoop
start-dfs.sh && start-yarn.sh

# 2. 上传数据到 HDFS
hdfs dfs -mkdir -p /Car
hdfs dfs -put data/dsv13r1.csv /Car/

# 3. 配置数据库
cp db.properties.example db.properties
# 编辑 db.properties 填入真实 MySQL 密码

# 4. 编译打包
cd ~/project/Enge1relase
javac -encoding UTF-8 -source 1.7 -target 1.7 \
    -classpath "$(hadoop classpath):lib/mysql-connector.jar" \
    -d target/classes $(find src/main/java -name "*.java")
jar cf target/Enge1relase.jar -C target/classes .

# 5. 运行单个任务
HADOOP_CLASSPATH=lib/mysql-connector.jar \
hadoop jar target/Enge1relase.jar com.neu.datapro.V1c1
```

## 任务输出示例

### V1c1 — 按小时平均电压/电流

| 小时 | 平均电压 | 平均电流 |
|------|---------|----------|
| 00 | 327.89 | -73.73 |
| 11 | 326.73 | -22.5 |
| 12 | 330.95 | -22.5 |
| 13 | 340.08 | -22.5 |
| 14 | 352.79 | -22.5 |

### V7 — 按电池状态温度

| 状态 | 平均最高温 | 平均最低温 |
|------|-----------|-----------|
| low | 33.17 | 31.41 |
| medium | 35.92 | 33.87 |
| high | 37.00 | 35.00 |
