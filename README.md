# Enge1relase — 新能源充电桩大数据分析项目

电动车充电数据 MapReduce 分析项目，包含 7 个任务，覆盖电压、电流、温度、能量等多维度统计。

> 配套讲稿：[course/701/新能源充电桩大数据项目实训讲稿.md](../course/701/新能源充电桩大数据项目实训讲稿.md)

## 技术栈

- **Hadoop** 2.6.5 — MapReduce 计算框架（讲稿使用 2.7.7，兼容）
- **MySQL** — 结果持久化存储
- **Java** 1.7/1.8 — 开发语言
- **Datart** — BI 可视化平台（详见 [datart/](datart/)）

## 项目结构

```
Enge1relase/
├── data/
│   └── dsv13r1.csv                         # 原始充电桩数据（1593 行）
├── datart/                                 # Datart 可视化配置
│   ├── datart.conf                         # Datart 服务配置文件
│   ├── sql-views.sql                       # 7 个 SQL View 定义
│   └── dashboard-config.md                 # 图表与看板配置指南
├── docs/
│   └── commands.md                         # 完整命令速查表
├── lib/
│   └── mysql-connector.jar                 # MySQL JDBC 驱动
├── scripts/                                # 自动化脚本
│   ├── compile.sh                          # 编译打包
│   ├── upload_data.sh                      # 上传数据到 HDFS
│   ├── run_v1c1.sh                         # 运行 V1 任务
│   ├── run_single.sh                       # 运行任意单个任务
│   ├── run_v2_v7.sh                        # 批量运行 V2~V7
│   ├── run_all.sh                          # 批量运行全部 V1~V7
│   └── verify_results.sh                   # 验证运行结果
├── sql/
│   └── create_tables.sql                   # 数据库和表创建脚本
├── src/main/java/com/neu/datapro/
│   ├── V1c1.java                           # 任务1: 按小时平均电压/电流
│   ├── V2c1.java                           # 任务2: 按小时电压极值
│   ├── V3_timeTempMinMax.java              # 任务3: 按小时温度极值
│   ├── V4_Ava_Ene_Cap.java                 # 任务4: 按小时能量/容量
│   ├── V5_chargeCurrent.java               # 任务5: 按小时充电电流统计
│   ├── V6_VA.java                          # 任务6: 按小时电压/电流变化率
│   └── V7_battryStatusAvg.java             # 任务7: 按电池状态温度统计
├── pom.xml
├── db.properties.example                   # 数据库配置模板
├── README.md
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

### 前提条件

- Hadoop 已启动（`start-dfs.sh && start-yarn.sh`，`jps` 能看到 5 个进程）
- MySQL 已启动（`sudo systemctl start mysql`）
- 项目位于 `~/project/Enge1relase`

### 一键运行

```bash
cd ~/project/Enge1relase

# Step 1: 配置数据库连接
cp db.properties.example db.properties
# 编辑 db.properties（默认配置通常无需修改）

# Step 2: 初始化 MySQL 数据库和表
sudo mysql < sql/create_tables.sql

# Step 3: 上传数据到 HDFS
bash scripts/upload_data.sh

# Step 4: 编译打包
bash scripts/compile.sh

# Step 5: 运行全部 7 个任务
bash scripts/run_all.sh

# Step 6: 验证结果
bash scripts/verify_results.sh
```

### 手动操作

```bash
# 1. 上传数据到 HDFS
hdfs dfs -mkdir -p /Car
hdfs dfs -put data/dsv13r1.csv /Car/

# 2. 编译打包
javac -encoding UTF-8 -source 1.7 -target 1.7 \
    -classpath "$(hadoop classpath):lib/mysql-connector.jar" \
    -d target/classes $(find src/main/java -name "*.java")
jar cf target/Enge1relase.jar -C target/classes .

# 3. 运行单个任务
hdfs dfs -rm -r -f /Car/v1
HADOOP_CLASSPATH=lib/mysql-connector.jar \
hadoop jar target/Enge1relase.jar com.neu.datapro.V1c1
```

## 脚本参考

| 脚本 | 功能 | 用法 |
|------|------|------|
| `scripts/compile.sh` | 编译全部源码并打包 JAR | `bash scripts/compile.sh` |
| `scripts/upload_data.sh` | 上传 CSV 数据到 HDFS | `bash scripts/upload_data.sh` |
| `scripts/run_v1c1.sh` | 运行 V1 任务并显示结果 | `bash scripts/run_v1c1.sh` |
| `scripts/run_single.sh` | 运行指定的单个任务 | `bash scripts/run_single.sh V2c1` |
| `scripts/run_v2_v7.sh` | 批量运行 V2~V7 | `bash scripts/run_v2_v7.sh` |
| `scripts/run_all.sh` | 批量运行全部 V1~V7 | `bash scripts/run_all.sh` |
| `scripts/verify_results.sh` | 检查 HDFS 和 MySQL 结果 | `bash scripts/verify_results.sh` |

## SQL 表结构

| 表名 | 列 | 说明 |
|------|-----|------|
| `t_enger1` | `record_time`, `avg_pack_voltage`, `avg_charge_current` | 按小时平均电压/电流 |
| `t_enger2` | `mmcv`, `max_pack_voltage`, `min_pack_voltage` | 电芯电压极值 |
| `t_enger3` | `recordTime`, `maxTemperature`, `minTemperature` | 温度极值 |
| `t_enger4` | `recordTime`, `energy`, `capacity` | 能量与容量 |
| `t_enger5` | `recordTime`, `avgchargeCurrent`, `maxchargeCurrent` | 充电电流统计 |
| `t_enger6` | `recordTime`, `packVoltage`, `chargeCurrent` | 电压电流变化率 |
| `t_enger7` | `batteryStatus`, `avgMaxTemperature`, `avgMinTemperature` | 电池状态温度 |

执行 `sudo mysql < sql/create_tables.sql` 一键创建全部表。

## Datart 可视化

项目包含完整的 Datart BI 可视化配置，详见 [datart/dashboard-config.md](datart/dashboard-config.md)。

**流程概览**：

1. 安装并启动 Datart → 访问 `http://localhost:8080`
2. 创建 JDBC 数据源 `enger_mysql` → 连接 `enger` 数据库
3. 创建 7 个 SQL View → 见 [datart/sql-views.sql](datart/sql-views.sql)
4. 创建 7 个图表（折线图/柱状图）
5. 搭建 Dashboard 看板"新能源充电桩数据分析看板"
6. 发布并全屏展示

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

## 常见问题排查

### 环境类

| 问题 | 现象 | 解决方案 |
|------|------|----------|
| Hadoop 无法启动 | `jps` 看不到 NameNode | 检查 `hdfs namenode -format` 是否执行成功 |
| SSH 免密失败 | `ssh localhost` 需要密码 | 重新生成密钥，检查 `authorized_keys` 权限为 600 |
| 端口被占用 | 50070 或 8080 无法访问 | `sudo lsof -i :端口号` 查看占用进程 |
| 虚拟机网络不通 | 无法 ping 通外网 | 检查 VMware 网络设置，使用 NAT 模式 |

### MapReduce 类

| 问题 | 现象 | 解决方案 |
|------|------|----------|
| 编译报错 | `javac` 提示语法错误 | 检查 Java 版本，确保使用 `-source 1.7` |
| 找不到主类 | `ClassNotFoundException` | 检查 `job.setJarByClass` 是否设置 |
| MySQL 驱动缺失 | `No suitable driver found` | 下载驱动放到 `/opt/hadoop/share/hadoop/common/lib/` |
| 认证失败 | `Access denied for user` | 检查 `db.properties` 中的用户名密码 |
| 公钥检索 | `Public Key Retrieval is not allowed` | JDBC URL 添加 `allowPublicKeyRetrieval=true` |
| 表不存在 | `Table doesn't exist` | 执行 `sudo mysql < sql/create_tables.sql` |

### Datart 类

| 问题 | 现象 | 解决方案 |
|------|------|----------|
| 启动失败 | 端口未监听 | 查看 `nohup.out` 日志，检查数据库连接 |
| 数据源连接失败 | Test connection 报错 | 检查 MySQL 服务、用户名、密码、JDBC URL |
| 视图无数据 | `No database selected` | SQL 中指定数据库名：`SELECT * FROM enger.t_enger1` |
| 图表无字段 | Columns 区域为空 | 检查视图是否关联正确的数据源 |

## 项目流程

```
┌─────────────────────────────────────────────────────────────┐
│                    新能源充电桩大数据分析项目                │
├─────────────────────────────────────────────────────────────┤
│  第1-2课时  │  虚拟机环境搭建 + Ubuntu 基础配置             │
│  第3-5课时  │  JDK 安装 + Hadoop 安装 + 伪分布式配置 + 启动 │
│  第6课时    │  HDFS 操作 + 数据上传                         │
│  第7-8课时  │  MapReduce 原理 + V1 代码详解                 │
│  第9-10课时 │  代码修改适配 + 编译打包 + V1 运行调试        │
│  第11-13课时│  V2~V7 代码解析 + 批量运行 + 结果验证         │
│  第14-15课时│  MySQL 安装 + 建表 + 数据导入                 │
│  第16-18课时│  Datart 安装 + 数据源配置 + 图表看板创建      │
│  第19-20课时│  问题排查 + 项目总结 + 答辩                   │
└─────────────────────────────────────────────────────────────┘
```
