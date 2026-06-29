package com.neu.datapro;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

/**
 * V1c1 任务:按小时统计平均电池包电压和平均充电电流
 *
 * 输入:/Car/dsv13r1.csv
 * 输出:/Car/v1/part-r-00000 + MySQL t_enger1 表
 *
 * 输出格式:小时 \t 平均电压,平均电流
 * 例如:13	398.85,120.9
 */
public class V1c1 {

    /**
     * Mapper
     *
     * 输入 :<LongWritable,Text> → <行号,CSV行内容>
     * 输出 :<Text,Text>         → <小时,电压+","+电流>
     *
     * 功能:从CSV中提取小时、电压、电流
     */
    public static class VoltageCurrentMapper
            extends Mapper<LongWritable, Text, Text, Text> {

        public void map(LongWritable key, Text value, Context context)
                throws IOException, InterruptedException {

            // 1. 按逗号分割CSV行,得到字段数组
            // fields[0]=序号,[1]=时间,[2]=电量,[3]=电压,
            // [4]=电流,[5]=最高单体电压,[6]=最低单体电压,
            // [7]=最高温度,[8]=最低温度,[9]=能量,[10]=容量
            String[] fields = value.toString().split(",");

            // 2. 提取时间字段(第2列,索引1)
            // 格式:yyyyMMddHHmmss (如 20190726111742)
            String recordTime = fields[1];

            // 3. 截取小时(第8-9位)
            // 例如"20190726111742"→substring(8,10)→"11"
            String hour = recordTime.substring(8, 10);

            // 4. 提取电压(第4列)和电流(第5列)
            String packVoltage = fields[3];
            String chargeCurrent = fields[4];

            // 5. 数据清洗:过滤无效数据(电压或电流为0.00则跳过)
            if (packVoltage.equals("0.00") || chargeCurrent.equals("0.00")) {
                return; // 不输出这条记录
            }

            // 6. 输出键值对
            // key:小时,value:电压+","+电流
            context.write(new Text(hour),
                    new Text(packVoltage + "," + chargeCurrent));
        }
    }

    /**
     * Reducer
     *
     * 输入 :<Text,Iterable<Text>> → <小时,[电压+","+电流, ...]>
     * 输出 :<Text,Text>           → <小时,平均电压,平均电流>
     *
     * 功能:计算每个小时的平均电压和平均电流
     */
    public static class VoltageCurrentReducer
            extends Reducer<Text, Text, Text, Text> {

        private Connection connection;
        private PreparedStatement preparedStatement;

        /**
         * setup:在reduce()执行前执行一次
         * 用途:建立数据库连接,清空旧数据
         */
        public void setup(Context context) {
            // JDBC连接参数 — 从 Hadoop Configuration 读取
            Configuration conf = context.getConfiguration();
            String url = conf.get("db.url");
            String user = conf.get("db.user");
            String password = conf.get("db.password");

            try {
                // 1. 建立数据库连接
                connection = DriverManager.getConnection(url, user, password);

                // 2. 清空旧数据(避免重复插入)
                String deleteQuery = "DELETE FROM t_enger1";
                PreparedStatement deleteStatement =
                        connection.prepareStatement(deleteQuery);
                deleteStatement.executeUpdate();

                // 3. 预编译INSERT语句
                String query = "INSERT INTO t_enger1 (record_time, "
                        + "avg_pack_voltage, avg_charge_current) VALUES (?, ?, ?)";
                preparedStatement = connection.prepareStatement(query);

            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        }

        /**
         * reduce:每个小时调用一次
         *
         * @param key    小时(如"11")
         * @param values 该小时所有记录的电压和电流列表
         */
        public void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {

            int count = 0;
            double totalPackVoltage = 0.0;
            double totalChargeCurrent = 0.0;

            // 1. 遍历所有值,累加
            for (Text value : values) {
                String[] fields = value.toString().split(",");
                totalPackVoltage += Double.parseDouble(fields[0]);
                totalChargeCurrent += Double.parseDouble(fields[1]);
                count++;
            }

            // 2. 计算平均值
            double avgPackVoltage = totalPackVoltage / count;
            double avgChargeCurrent = totalChargeCurrent / count;

            // 3. 写入MySQL
            try {
                preparedStatement.setString(1, key.toString());
                preparedStatement.setDouble(2, avgPackVoltage);
                preparedStatement.setDouble(3, avgChargeCurrent);
                preparedStatement.executeUpdate();
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }

            // 4. 写入HDFS
            context.write(key, new Text(avgPackVoltage + "," + avgChargeCurrent));
        }

        /**
         * cleanup:在reduce()执行完后执行一次
         * 用途:关闭数据库连接,释放资源
         */
        public void cleanup(Context context) {
            try {
                if (preparedStatement != null) preparedStatement.close();
                if (connection != null) connection.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Driver
     *
     * 功能:配置并提交MapReduce作业
     */
    public static void main(String[] args) throws Exception {

        // 1. 创建配置，从 db.properties 加载数据库连接参数
        Configuration conf = new Configuration();
        conf.set("fs.defaultFS", "hdfs://localhost:9000");

        Properties dbProps = new Properties();
        String[] paths = {"db.properties",
                          System.getProperty("user.home") + "/project/Enge1relase/db.properties"};
        java.io.InputStream in = null;
        for (String p : paths) {
            try {
                in = new FileInputStream(p);
                break;
            } catch (IOException ignored) {}
        }
        if (in == null) {
            System.err.println("ERROR: db.properties not found!");
            System.err.println("Copy db.properties.example to db.properties and fill in your credentials.");
            System.exit(1);
        }
        dbProps.load(in);
        conf.set("db.url", dbProps.getProperty("db.url"));
        conf.set("db.user", dbProps.getProperty("db.user"));
        conf.set("db.password", dbProps.getProperty("db.password"));

        // 2. 创建Job
        String jobName = "v1c1";
        Job job = Job.getInstance(conf, jobName);
        job.setJarByClass(V1c1.class); // 必须设置!

        // 3. 设置Mapper
        job.setMapperClass(VoltageCurrentMapper.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        // 4. 设置Reducer
        job.setReducerClass(VoltageCurrentReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        // 5. 设置输入输出路径
        String dataDir = "/Car/dsv13r1.csv";
        String outputDir = "/Car/v1";
        Path inPath = new Path("hdfs://localhost:9000" + dataDir);
        Path outPath = new Path("hdfs://localhost:9000" + outputDir);
        FileInputFormat.addInputPath(job, inPath);
        FileOutputFormat.setOutputPath(job, outPath);

        // 6. 如果输出目录已存在,先删除
        FileSystem fs = FileSystem.get(conf);
        if (fs.exists(outPath)) {
            fs.delete(outPath, true);
        }

        // 7. 提交作业
        System.out.println("Job: " + jobName + " is running ... ");
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
