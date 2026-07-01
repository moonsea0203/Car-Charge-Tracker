-- ============================================================
-- Datart SQL View 定义 — 对应讲稿第 17 课时
--
-- 使用方法：
--   1. 登录 Datart (http://localhost:8080)
--   2. 左侧菜单 → Views → + → SQL View
--   3. 选择数据源 enger_mysql
--   4. 将下方对应的 SQL 粘贴到编辑器中
--   5. 命名并保存
-- ============================================================

-- View 1: v1_voltage_current — 按小时电压电流趋势
SELECT * FROM enger.t_enger1;

-- View 2: v2_cell_voltage — 电芯电压极值
SELECT * FROM enger.t_enger2;

-- View 3: v3_temperature — 温度极值趋势
SELECT * FROM enger.t_enger3;

-- View 4: v4_energy_capacity — 能量与容量趋势
SELECT * FROM enger.t_enger4;

-- View 5: v5_charge_current — 充电电流统计
SELECT * FROM enger.t_enger5;

-- View 6: v6_voltage_current_change — 电压电流变化率
SELECT * FROM enger.t_enger6;

-- View 7: v7_battery_status — 电池状态温度分布
SELECT * FROM enger.t_enger7;
