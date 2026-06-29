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
 * V3 任务:按小时统计最高温度和最低温度极值
 *
 * 输入:/Car/dsv13r1.csv
 * 输出:/Car/v3/part-r-00000 + MySQL t_enger3 表
 */
public class V3_timeTempMinMax {

    public static class TempExtremeMapper
            extends Mapper<LongWritable, Text, Text, Text> {

        public void map(LongWritable key, Text value, Context context)
                throws IOException, InterruptedException {

            String[] fields = value.toString().split(",");
            String recordTime = fields[1];
            String hour = recordTime.substring(8, 10);
            String maxTemp = fields[7];
            String minTemp = fields[8];

            if (maxTemp.equals("0.00") && minTemp.equals("0.00")) {
                return;
            }

            context.write(new Text(hour), new Text(maxTemp + "," + minTemp));
        }
    }

    public static class TempExtremeReducer
            extends Reducer<Text, Text, Text, Text> {

        private Connection connection;
        private PreparedStatement preparedStatement;

        public void setup(Context context) {
            Configuration conf = context.getConfiguration();
            String url = conf.get("db.url");
            String user = conf.get("db.user");
            String password = conf.get("db.password");

            try {
                connection = DriverManager.getConnection(url, user, password);
                String deleteQuery = "DELETE FROM t_enger3";
                PreparedStatement deleteStatement =
                        connection.prepareStatement(deleteQuery);
                deleteStatement.executeUpdate();
                String query = "INSERT INTO t_enger3 (recordTime, maxTemperature, "
                        + "minTemperature) VALUES (?, ?, ?)";
                preparedStatement = connection.prepareStatement(query);
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        }

        public void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {

            double globalMaxTemp = Double.MIN_VALUE;
            double globalMinTemp = Double.MAX_VALUE;

            for (Text value : values) {
                String[] fields = value.toString().split(",");
                double maxT = Double.parseDouble(fields[0]);
                double minT = Double.parseDouble(fields[1]);
                if (maxT > globalMaxTemp) globalMaxTemp = maxT;
                if (minT < globalMinTemp) globalMinTemp = minT;
            }

            try {
                preparedStatement.setString(1, key.toString());
                preparedStatement.setDouble(2, globalMaxTemp);
                preparedStatement.setDouble(3, globalMinTemp);
                preparedStatement.executeUpdate();
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }

            context.write(key, new Text(globalMaxTemp + "," + globalMinTemp));
        }

        public void cleanup(Context context) {
            try {
                if (preparedStatement != null) preparedStatement.close();
                if (connection != null) connection.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        conf.set("fs.defaultFS", "hdfs://localhost:9000");

        Properties dbProps = new Properties();
        String[] paths = {"db.properties",
                          System.getProperty("user.home") + "/project/Enge1relase/db.properties"};
        java.io.InputStream in = null;
        for (String p : paths) {
            try { in = new FileInputStream(p); break; }
            catch (IOException ignored) {}
        }
        if (in == null) {
            System.err.println("ERROR: db.properties not found!");
            System.exit(1);
        }
        dbProps.load(in);
        conf.set("db.url", dbProps.getProperty("db.url"));
        conf.set("db.user", dbProps.getProperty("db.user"));
        conf.set("db.password", dbProps.getProperty("db.password"));

        String jobName = "v3";
        Job job = Job.getInstance(conf, jobName);
        job.setJarByClass(V3_timeTempMinMax.class);

        job.setMapperClass(TempExtremeMapper.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        job.setReducerClass(TempExtremeReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        String dataDir = "/Car/dsv13r1.csv";
        String outputDir = "/Car/v3";
        Path inPath = new Path("hdfs://localhost:9000" + dataDir);
        Path outPath = new Path("hdfs://localhost:9000" + outputDir);
        FileInputFormat.addInputPath(job, inPath);
        FileOutputFormat.setOutputPath(job, outPath);

        FileSystem fs = FileSystem.get(conf);
        if (fs.exists(outPath)) {
            fs.delete(outPath, true);
        }

        System.out.println("Job: " + jobName + " is running ... ");
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
