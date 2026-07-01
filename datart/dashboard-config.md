# Datart 可视化看板配置指南

> 对应讲稿第 16-18 课时

---

## 一、Datart 安装与启动（第 16 课时）

### 1.1 下载与解压

将 `datart-server-1.0.0-beta.4-install.zip` 放到桌面，然后执行：

```bash
mkdir -p ~/project/datart
cd ~/project/datart
unzip ~/Desktop/datart-server-1.0.0-beta.4-install.zip
```

### 1.2 配置数据库连接

```bash
# 复制配置文件
cp ~/project/Enge1relase/datart/datart.conf ~/project/datart/config/datart.conf

# 或者手动编辑
vim ~/project/datart/config/datart.conf
```

配置内容见 `datart/datart.conf`。

### 1.3 创建 Datart 专用数据库和用户

```sql
sudo mysql
```

```sql
CREATE DATABASE IF NOT EXISTS datart DEFAULT CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'datart'@'localhost' IDENTIFIED BY 'datart123';
GRANT ALL PRIVILEGES ON datart.* TO 'datart'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 1.4 启动 Datart

```bash
cd ~/project/datart
chmod +x ./bin/*.sh
./bin/datart-server.sh start
```

验证启动：

```bash
ss -lntp | grep 8080
# 应显示 8080 端口处于 LISTEN 状态
```

浏览器访问 `http://localhost:8080`，首次进入会要求初始化（填写邮箱和密码）。

---

## 二、数据源配置（第 17 课时）

### 2.1 创建 JDBC 数据源

1. 登录 Datart，左侧菜单点击 **Sources**（数据源）
2. 点击 **+ Create Source**
3. 填写以下信息：

| 字段 | 值 |
|------|-----|
| Name | `enger_mysql` |
| Type | `JDBC` |
| Database type | `MYSQL` |
| Connection URL | `jdbc:mysql://localhost:3306/enger?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&characterEncoding=utf8` |
| User | `bi` |
| Password | `bi123456` |
| Driver class | `com.mysql.cj.jdbc.Driver` |

4. 点击 **Test connection** → 测试成功 → 点击 **Save**

### 2.2 创建 SQL View

为每张结果表创建一个 SQL View。SQL 语句见 `datart/sql-views.sql`。

| 序号 | 视图名称 | SQL | 对应表 |
|------|---------|-----|--------|
| 1 | `v1_voltage_current` | `SELECT * FROM enger.t_enger1` | t_enger1 |
| 2 | `v2_cell_voltage` | `SELECT * FROM enger.t_enger2` | t_enger2 |
| 3 | `v3_temperature` | `SELECT * FROM enger.t_enger3` | t_enger3 |
| 4 | `v4_energy_capacity` | `SELECT * FROM enger.t_enger4` | t_enger4 |
| 5 | `v5_charge_current` | `SELECT * FROM enger.t_enger5` | t_enger5 |
| 6 | `v6_voltage_current_change` | `SELECT * FROM enger.t_enger6` | t_enger6 |
| 7 | `v7_battery_status` | `SELECT * FROM enger.t_enger7` | t_enger7 |

> **注意**：如果报错 `No database selected`，在 SQL 中加上数据库名前缀（如 `enger.t_enger1`），如上表所示。

创建步骤：
1. 左侧菜单 → **Views** → **+** → **SQL View**
2. 选择数据源 `enger_mysql`
3. 粘贴对应 SQL，填写视图名称
4. 点击保存，进入详情页确认能看到数据预览

---

## 三、图表创建（第 18 课时）

### 3.1 图表配置总览

在 Views 页面，点击视图名称 → **Start Analysis**，按以下配置创建图表：

| 视图 | 图表名称 | 类型 | Dimension（维度） | Metrics（指标） |
|------|---------|------|-------------------|----------------|
| `v1_voltage_current` | 电压电流趋势图 | Line（折线图） | `record_time` | `avg_pack_voltage`, `avg_charge_current` |
| `v2_cell_voltage` | 电芯电压极值 | Bar（柱状图） | `mmcv` | `max_pack_voltage`, `min_pack_voltage` |
| `v3_temperature` | 温度趋势 | Line（折线图） | `recordTime` | `maxTemperature`, `minTemperature` |
| `v4_energy_capacity` | 能量与容量趋势 | Line（折线图） | `recordTime` | `energy`, `capacity` |
| `v5_charge_current` | 充电电流统计 | Line（折线图） | `recordTime` | `avgchargeCurrent`, `maxchargeCurrent` |
| `v6_voltage_current_change` | 电压电流变化率 | Line（折线图） | `recordTime` | `packVoltage`, `chargeCurrent` |
| `v7_battery_status` | 电池状态温度分布 | Bar（柱状图） | `batteryStatus` | `avgMaxTemperature`, `avgMinTemperature` |

### 3.2 图表创建步骤（以 V1 为例）

1. 进入 Views 页面，点击 `v1_voltage_current` 视图
2. 点击右上角 **Start Analysis**
3. 选择图表类型 **Line**（折线图）
4. 在左侧字段列表中：
   - 将 `record_time` 拖入 **Dimension**（维度）区域
   - 将 `avg_pack_voltage` 和 `avg_charge_current` 拖入 **Metrics**（指标）区域
5. 点击 **Save**，命名为 `电压电流趋势图`

---

## 四、Dashboard 看板搭建（第 18 课时）

### 4.1 创建 Dashboard

1. 左侧菜单 → **Dashboards**
2. 点击 **+ Create Dashboard**
3. 命名为 `新能源充电桩数据分析看板`
4. 进入编辑页面

### 4.2 添加图表

1. 点击 **添加图表** 按钮
2. 依次选择已创建的 7 个图表
3. 拖拽调整位置和大小，建议布局：

```
┌──────────────────────────────────────────────────────┐
│              新能源充电桩大数据分析                   │
├─────────────────────┬────────────────────────────────┤
│   电压电流趋势图     │     充电电流统计               │
│   (折线图)          │     (折线图)                    │
├─────────────────────┼────────────────────────────────┤
│   能量与容量趋势     │     电压电流变化率             │
│   (折线图)          │     (折线图)                    │
├─────────────────────┼────────────────────────────────┤
│   温度趋势           │     电池状态温度分布           │
│   (折线图)          │     (柱状图)                    │
├─────────────────────┴────────────────────────────────┤
│   电芯电压极值 (柱状图)                              │
└──────────────────────────────────────────────────────┘
```

4. 点击 **Save** 保存
5. 点击 **Publish** 发布

### 4.3 大屏效果优化

1. **设置深色背景**：Dashboard 设置 → 背景色 → 深色
2. **添加标题**：插入文本组件 → `新能源充电桩大数据分析`
3. **添加指标卡片**（可选）：
   - 总记录数：使用 V1 视图，选择 Count 聚合
   - 平均电压：使用 V1 视图，avg_pack_voltage 的平均值
   - 平均温度：使用 V3 视图
4. **调整颜色**：图表设置中统一配色
5. **全屏展示**：点击 **Presentation** 模式

---

## 五、常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 8080 端口无法访问 | Datart 未启动 | `cd ~/project/datart && ./bin/datart-server.sh start` |
| 启动失败 | 数据库连接错误 | 检查 `config/datart.conf` 配置，确认 MySQL 已启动 |
| 数据源 Test connection 失败 | JDBC URL 或用户名密码错误 | 检查 MySQL 是否启动，用户 `bi` 是否有权限 |
| 视图无数据 | `No database selected` | SQL 中加上数据库名前缀：`SELECT * FROM enger.t_enger1` |
| 图表 Columns 为空 | 视图未关联正确的数据源 | 检查视图是否选择了 `enger_mysql` 数据源 |
| 端口被占用 | 其他程序占用 8080 | 修改 `datart.conf` 中 `server.port`，或 `sudo lsof -i :8080` 查看占用进程 |

---

## 六、关闭与重启

```bash
# 停止 Datart
cd ~/project/datart
./bin/datart-server.sh stop

# 启动 Datart
./bin/datart-server.sh start

# 查看日志
tail -f nohup.out
```
