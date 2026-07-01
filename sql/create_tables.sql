-- ============================================================
-- 新能源充电桩大数据项目 — 数据库初始化脚本
-- 对应讲稿第 14-15 课时
--
-- 使用方法：
--   sudo mysql < sql/create_tables.sql
--
-- 或者登录 MySQL 后执行：
--   source sql/create_tables.sql;
-- ============================================================

-- 1. 创建业务数据库
CREATE DATABASE IF NOT EXISTS enger DEFAULT CHARACTER SET utf8mb4;

-- 2. 创建 BI 工具专用用户
-- 注意：CREATE USER IF NOT EXISTS 需要 MySQL 5.7+ / 8.0+
-- 如果版本较老报错，请改用：
--   GRANT ALL PRIVILEGES ON enger.* TO 'bi'@'localhost' IDENTIFIED BY 'bi123456';
CREATE USER IF NOT EXISTS 'bi'@'localhost' IDENTIFIED BY 'bi123456';
GRANT ALL PRIVILEGES ON enger.* TO 'bi'@'localhost';
FLUSH PRIVILEGES;

USE enger;

-- ============================================================
-- 3. 创建 7 张结果表（列名与 Java 源码 INSERT 语句严格一致）
-- ============================================================

-- V1: 按小时平均电池包电压和充电电流
CREATE TABLE IF NOT EXISTS t_enger1 (
    record_time       VARCHAR(10),
    avg_pack_voltage  DOUBLE,
    avg_charge_current DOUBLE
);

-- V2: 电芯电压极值（最大值和最小值）
CREATE TABLE IF NOT EXISTS t_enger2 (
    mmcv              VARCHAR(20),
    max_pack_voltage  DOUBLE,
    min_pack_voltage  DOUBLE
);

-- V3: 按小时温度极值
CREATE TABLE IF NOT EXISTS t_enger3 (
    recordTime        VARCHAR(10),
    maxTemperature    DOUBLE,
    minTemperature    DOUBLE
);

-- V4: 按小时总能量和总容量
CREATE TABLE IF NOT EXISTS t_enger4 (
    recordTime        VARCHAR(10),
    energy            DOUBLE,
    capacity          DOUBLE
);

-- V5: 充电电流平均值和最大值
CREATE TABLE IF NOT EXISTS t_enger5 (
    recordTime        VARCHAR(10),
    avgchargeCurrent  DOUBLE,
    maxchargeCurrent  DOUBLE
);

-- V6: 电压变化率和电流变化率
CREATE TABLE IF NOT EXISTS t_enger6 (
    recordTime        VARCHAR(10),
    packVoltage       DOUBLE,
    chargeCurrent     DOUBLE
);

-- V7: 不同电池状态下的平均温度
CREATE TABLE IF NOT EXISTS t_enger7 (
    batteryStatus       VARCHAR(30),
    avgMaxTemperature   DOUBLE,
    avgMinTemperature   DOUBLE
);

-- ============================================================
-- 4. 验证
-- ============================================================
-- 查看所有表：
--   USE enger;
--   SHOW TABLES;
--
-- 查看表结构：
--   DESCRIBE t_enger1;
--
-- 查看数据：
--   SELECT * FROM t_enger1 LIMIT 10;
--   SELECT COUNT(*) FROM t_enger1;
