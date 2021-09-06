#!/bin/bash
# 部署环境初始化脚本
# 需要先修改同在 _deploy 下的 _config.sh 文件
# 该脚本负责执行以下操作：
# - docker-compose.yml 文件生成
# - 生成 update.sh exec.sh tail.sh restart.sh 几个常用脚本
# docker-compose.yml.template 文件随项目固定，基本不会变动。若要修改，请通过 git 提交
# 该脚本随项目 _deploy 分发，脚本内参数仅与 docker-compose 定义有关
#
# usage:
#   ./init.sh xxxx/xxxxx:xxx # 提供完整 image ，直接使用，优先度高
#   ./init.sh                # 提供 version.txt 文件，写入 image 使用
#
# env:
#   - LOG_DIR    日志存放目录，优先于 _config.sh
#
# mark_zhou[zz.mark06@gmail.com]

set -e

_DEPLOY_DIR=$(cd `dirname $0`; pwd)
WORKSPACE_DIR=$(pwd)

# 保存环境变量中的 LOG_DIR
_LOG_DIR=${LOG_DIR}

echo "加载配置 ${_DEPLOY_DIR}/_config.sh"
source ${_DEPLOY_DIR}/_config.sh

# 优先使用脚本后的参数
if [ ! -n "$1" ];then
    # 无参数则从文件获取
    VERSION_FILE_PATH=${_DEPLOY_DIR}/version.txt
    if [ ! -f ${VERSION_FILE_PATH} ]; then
        echo "缺少 version 参数 无法执行脚本"
        exit 1
    else
        export IMAGE_TAG=$(< ${VERSION_FILE_PATH})
        export IMAGE=${IMAGE_BASE}:${IMAGE_TAG}
    fi
else
    export IMAGE=$1
fi

# 以下生成部分
echo "准备生成镜像 ${IMAGE} 相关运行文件"

# 脚本执行前，环境变量中存在 LOG_DIR，优先使用
if [ -z ${_LOG_DIR} ];then
    _LOG_DIR=${LOG_DIR}
fi

# docker-compose.yml
LOG_DIR=${_LOG_DIR}
echo "生成 docker-compose.yml 到 ${WORKSPACE_DIR}/docker-compose.yml"
eval "cat <<EOF
$(< ${_DEPLOY_DIR}/docker-compose.yml.template)
EOF
"  > ${WORKSPACE_DIR}/docker-compose.yml

# update.sh
echo "生成 update.sh 到 ${WORKSPACE_DIR}/update.sh"
export __SERVICE_NAME=${SERVICE_NAME}
eval "cat <<EOF
$(< ${_DEPLOY_DIR}/update.sh.template)
EOF
"  > ${WORKSPACE_DIR}/update.sh

# exec.sh
echo "生成 exec.sh 到 ${WORKSPACE_DIR}/exec.sh"
cat << EOF > ${WORKSPACE_DIR}/exec.sh
docker-compose exec ${SERVICE_NAME} bash
EOF

# tail.sh
echo "生成 tail.sh 到 ${WORKSPACE_DIR}/tail.sh"
cat << EOF > ${WORKSPACE_DIR}/tail.sh
docker-compose logs -f --tail 20
EOF

# restart.sh
echo "生成 restart.sh 到 ${WORKSPACE_DIR}/restart.sh"
cat << EOF > ${WORKSPACE_DIR}/restart.sh
docker-compose restart ${SERVICE_NAME}
EOF

# chmod +x
chmod +x ${WORKSPACE_DIR}/update.sh ${WORKSPACE_DIR}/exec.sh ${WORKSPACE_DIR}/tail.sh ${WORKSPACE_DIR}/restart.sh

# 写一个空的 application.yml
touch ${WORKSPACE_DIR}/application.yml
