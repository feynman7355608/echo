#!/bin/bash
# spug运维平台 配置文件处理脚本，会由 spug 部署逻辑执行
# 需要根据业务定制
#
# 基于 spring-boot 2.3+ template v1.0 环境
#
# 使用 application.yml 作为项目配置文件
# 脚本将环境变量中 __SPUG__开头的配置，写入文件中
#
# mark_zhou[zz.mark06@gmail.com]

set -e

_DEPLOY_DIR=$(cd `dirname $0`; pwd)
WORKSPACE_DIR=$(pwd)

if [ ! -n "$1" ];then
    echo "需要输入 应用-标识符"
    exit 1
fi

APP_TAG=$1
APP_TAG=${APP_TAG^^}
APP_TAG=${APP_TAG/-/_}
echo "应用标识符: ${APP_TAG}"

ENV_NAME=_SPUG_${APP_TAG}_APPLICATION_YML
echo "ENV_NAME: ${ENV_NAME}"
APPLICATION_YML="$(eval echo '$'$ENV_NAME})"
echo "json: ${APPLICATION_YML}"

YAML=$(echo "${APPLICATION_YML}" | docker run -i --rm  simplealpine/json2yaml)
echo "配置文件 application.yml"
echo ${YAML}

cat <<EOF > ${WORKSPACE_DIR}/application.yml
${YAML}
EOF
