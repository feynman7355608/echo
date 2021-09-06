# 该脚本随项目 _deploy 分发，脚本内参数仅与 docker镜像 docker-compose 定义有关

set -e

# 镜像地址，不包括tag
IMAGE_BASE=registry.cn-beijing.aliyuncs.com/zzmark/echo

# 服务名、监控服务名，仅支持小写、下划线
SERVICE_NAME=echo
MONITOR_SERVICE_NAME=monitor_echo

# 服务域名
DOMAIN="template-api.leadpcom.com"

# 日志位置，会被 init.sh 执行时的环境变量覆盖掉
LOG_DIR=/data/log/${SERVICE_NAME}
