# 完整命令速查表

> 对应讲稿附录 A~E

---

## A. 环境搭建命令

```bash
# 更新软件源
sudo apt update

# 安装基础工具
sudo apt install -y openssh-server vim net-tools wget curl unzip rsync maven python3 python3-pip python3-venv

# 安装 JDK 8
sudo apt install -y openjdk-8-jdk

# 配置 JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc

# 验证
java -version
echo $JAVA_HOME
```

---

## B. Hadoop 操作命令

```bash
# 配置 SSH 免密登录
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
ssh localhost   # 测试

# 格式化 NameNode（仅首次）
hdfs namenode -format

# 启动 Hadoop
start-dfs.sh
start-yarn.sh

# 查看进程（应看到 5 个：NameNode, DataNode, SecondaryNameNode, ResourceManager, NodeManager）
jps

# 停止 Hadoop
stop-yarn.sh
stop-dfs.sh

# HDFS 操作
hdfs dfs -mkdir -p /Car                       # 创建目录
hdfs dfs -put ~/project/dsv13r1.csv /Car/     # 上传文件
hdfs dfs -put -f local.csv /Car/              # 强制覆盖上传
hdfs dfs -ls /Car                             # 列出文件
hdfs dfs -cat /Car/v1/part-r-00000 | head     # 查看文件前几行
hdfs dfs -rm -r -f /Car/v1                    # 递归强制删除

# Web 界面
# NameNode: http://虚拟机IP:50070
# YARN:     http://虚拟机IP:8088
```

---

## C. MapReduce 编译运行命令

```bash
# 进入项目目录
cd ~/project/Enge1relase

# === 使用脚本（推荐）===

# 编译打包
bash scripts/compile.sh

# 上传数据到 HDFS
bash scripts/upload_data.sh

# 运行单个任务
bash scripts/run_single.sh V1c1
bash scripts/run_single.sh V2c1

# 运行 V1
bash scripts/run_v1c1.sh

# 批量运行 V2~V7
bash scripts/run_v2_v7.sh

# 运行全部 V1~V7
bash scripts/run_all.sh

# 验证结果
bash scripts/verify_results.sh

# === 手动操作 ===

# 编译
javac -encoding UTF-8 -source 1.7 -target 1.7 \
    -classpath "$(hadoop classpath):lib/mysql-connector.jar" \
    -d target/classes $(find src/main/java -name "*.java")

# 打包
jar cf target/Enge1relase.jar -C target/classes .

# 运行单个任务
hdfs dfs -rm -r -f /Car/v1
HADOOP_CLASSPATH=lib/mysql-connector.jar \
hadoop jar target/Enge1relase.jar com.neu.datapro.V1c1

# 批量运行
for cls in V1c1 V2c1 V3_timeTempMinMax V4_Ava_Ene_Cap V5_chargeCurrent V6_VA V7_battryStatusAvg; do
  echo "===== running $cls ====="
  hadoop jar target/Enge1relase.jar com.neu.datapro.$cls
done
```

---

## D. MySQL 操作命令

```bash
# 启动 MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# 登录 MySQL
sudo mysql

# 执行 SQL 脚本
sudo mysql < sql/create_tables.sql

# 常用 SQL
SHOW DATABASES;
USE enger;
SHOW TABLES;
DESCRIBE t_enger1;
SELECT * FROM t_enger1 LIMIT 10;
SELECT COUNT(*) FROM t_enger1;

# 命令行查询
mysql -u bi -pbi123456 -e "SELECT * FROM enger.t_enger1;"
mysql -u bi -pbi123456 -e "SELECT COUNT(*) FROM enger.t_enger1;"
```

---

## E. Datart 操作命令

```bash
# 安装 Datart
mkdir -p ~/project/datart
cd ~/project/datart
unzip ~/Desktop/datart-server-1.0.0-beta.4-install.zip

# 配置
cp ~/project/Enge1relase/datart/datart.conf config/datart.conf
chmod +x ./bin/*.sh

# 启动
./bin/datart-server.sh start

# 查看状态
ss -lntp | grep 8080

# 查看日志
tail -f nohup.out

# 停止
./bin/datart-server.sh stop

# 浏览器访问
# http://localhost:8080
```
