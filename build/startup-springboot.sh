#!/bin/bash
#
# 启动脚本
# 该脚本部分取自 vjkit，都做了注释，按需引用
# 仅支持 java 11+
#
# 支持的环境变量：
# - $NAME           应用名称
# - $JAVA_OPTS      jvm 参数
# - $JAVA_AGENT     jvm agent

# 基本参数
# appid 关系到日志文件名和一些其他的设置
APPID=${NAME:-application}

BASEPATH=$(cd `dirname $0`; pwd)
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')

# **************************************************************

# ************************** 以下JVM部分 ************************

# Enable coredump 容器环境暂不清楚是否可用，观望一手
# ulimit -c unlimited

## Memory Options, 根据实际情况进行调整，建议为内存总量一半，  容器环境，靠容器本体限制
# MEM_OPTS="-Xmx512m -Xms512m -XX:NewRatio=1 -XX:MetaspaceSize=192M -XX:MaxMetaspaceSize=192M"

# 启动时预申请内存
# MEM_OPTS="$MEM_OPTS -XX:+AlwaysPreTouch"

# 如果线程数较多，函数的递归较少，线程栈内存可以调小节约内存，默认1M。
MEM_OPTS="$MEM_OPTS -Xss512k"

# 堆外内存的最大值默认约等于堆大小，可以显式将其设小，获得一个比较清晰的内存总量预估
#MEM_OPTS="$MEM_OPTS -XX:MaxDirectMemorySize=2g"

# 根据JMX/VJTop的观察，调整二进制代码区大小避免满了之后不能再JIT，JDK7/8，是否打开多层编译的默认值都不一样
#MEM_OPTS="$MEM_OPTS -XX:ReservedCodeCacheSize=240M"


## GC Options##

GC_OPTS="-XX:+UseG1GC"

# System.gc() 使用并行算法
GC_OPTS="$GC_OPTS -XX:+ExplicitGCInvokesConcurrent"

# 根据应用的对象生命周期设定，减少事实上的老生代对象在新生代停留时间，加快YGC速度
# GC_OPTS="$GC_OPTS -XX:MaxTenuringThreshold=3"

# 如果OldGen较大，加大YGC时扫描OldGen关联的卡片，加快YGC速度，默认值256较低
# GC_OPTS="$GC_OPTS -XX:+UnlockDiagnosticVMOptions -XX:ParGCCardsPerStrideChunk=1024"

# 如果JVM并不独占机器，机器上有其他较繁忙的进程在运行，将GC线程数设置得比默认值(CPU核数＊5/8 )更低以减少竞争，反而会大大加快YGC速度。
#GC_OPTS="$GC_OPTS -XX:ParallelGCThreads=12 -XX:ConcGCThreads=6"


## GC log Options, only for JDK7/JDK8 ##

# 默认使用/dev/shm 内存文件系统避免在高IO场景下写GC日志时被阻塞导致STW时间延长
if [ -d /dev/shm/ ]; then
    GC_LOG_FILE=/dev/shm/gc-${APPID}.log
else
    mkdir -p ${BASEPATH}/gc/
	GC_LOG_FILE=${BASEPATH}/gc/gc-${APPID}.log
fi

if [ -f ${GC_LOG_FILE} ]; then
  GC_LOG_BACKUP=${BASEPATH}/gc/gc-${APPID}-$(date +'%Y%m%d_%H%M%S').log
  echo "saving gc log ${GC_LOG_FILE} to ${GC_LOG_BACKUP}"
  mkdir -p ${BASEPATH}/gc/
  mv ${GC_LOG_FILE} ${GC_LOG_BACKUP}
fi

#打印GC日志，包括时间戳，晋升老生代失败原因，应用实际停顿时间(含GC及其他原因)  暂且没摸清java11该怎么打印
#GCLOG_OPTS="-Xloggc:${GC_LOG_FILE} -XX:+PrintGCDetails -Xlog::::time,level,tags,safepoint"


# 打印安全点日志，找出GC日志里非GC的停顿的原因，会损失很多性能
#GCLOG_OPTS="$GCLOG_OPTS -XX:+PrintSafepointStatistics -XX:PrintSafepointStatisticsCount=1 -XX:+UnlockDiagnosticVMOptions -XX:-DisplayVMOutput -XX:+LogVMOutput -XX:LogFile=/dev/shm/vm-${APPID}.log"


## Optimization Options##

OPTIMIZE_OPTS="-XX:-UseBiasedLocking -XX:AutoBoxCacheMax=20000 -Djava.security.egd=file:/dev/./urandom"


# 关闭PerfData写入，避免高IO场景GC时因为写PerfData文件被阻塞，但会使得jstats，jps不能使用
#OPTIMIZE_OPTS="$OPTIMIZE_OPTS -XX:+PerfDisableSharedMem"

# 关闭多层编译，减少应用刚启动时的JIT导致的可能超时，以及避免部分函数C1编译后最终没被C2编译。 但导致函数没有被初始C1编译。
#if [[ "$JAVA_VERSION" > "1.8" ]]; then
#  OPTIMIZE_OPTS="$OPTIMIZE_OPTS -XX:-TieredCompilation"
#fi

# 如果希望无论函数的热度如何，最终JIT所有函数，关闭GC时将函数调用次数减半。
#OPTIMIZE_OPTS="$OPTIMIZE_OPTS -XX:-UseCounterDecay"

## Trouble shooting Options##
mkdir -p ${BASEPATH}/jvm/
SHOOTING_OPTS="-XX:+PrintCommandLineFlags -XX:-OmitStackTraceInFastThrow -XX:ErrorFile=${BASEPATH}/jvm/hs_err_%p.log"


# OOM 时进行HeapDump，但此时会产生较高的连续IO，如果是容器环境，有可能会影响他的容器
# mkdir -p ${BASEPATH}/dump/
# SHOOTING_OPTS="$SHOOTING_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${BASEPATH}/dump/"


# 在非生产环境，打开JFR进行性能记录（生产环境要收License）
#SHOOTING_OPTS="$SHOOTING_OPTS -XX:+UnlockCommercialFeatures -XX:+FlightRecorder -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints"


## JMX Options##

#开放JMX本地访问，设定端口号，可使用 jconsole 介入。容器场景不能限定 localhost -Djava.rmi.server.hostname=127.0.0.1
JMX_OPTS="-Dcom.sun.management.jmxremote.port=9012 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"


## Other Options##

## 远程 debug
# OTHER_OPTS="-Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"


## All together ##

JAVA_OPTS=${JAVA_OPTS:-"$MEM_OPTS $GC_OPTS $GCLOG_OPTS $OPTIMIZE_OPTS $SHOOTING_OPTS $JMX_OPTS $OTHER_OPTS"}
echo JAVA_OPTS=$JAVA_OPTS

# ****************************************************************

exec java $JAVA_OPTS $JAVA_AGENT org.springframework.boot.loader.JarLauncher "$@"
