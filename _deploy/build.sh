#!/bin/bash
# docker 构建脚本，完全使用 Dockerfile 构建流
# 编译、打包、生成 Docker Image 全都靠 Dockerfile 流程
#
# usage:
#   build.sh xxx  # 输入编译目标的 TAG 版本
#
# mark_zhou[zz.mark06@gmail.com]

set -e

_DEPLOY_DIR=$(cd `dirname $0`; pwd)
WORKSPACE_DIR=$(pwd)

source ${_DEPLOY_DIR}/_config.sh

if [ ! -n "$1" ];then
    echo "缺少 tag 参数 无法执行脚本"
    exit 1
fi

IMAGE_TAG=$1
IMAGE=${IMAGE_BASE}:${IMAGE_TAG}

# 判断 docker ，高版本使用 buildx 低版本使用普通的
# 18.09 后，docker 支持 buildkit 特性，可以更好的使用缓存
# 按照官方建议，最好可以使用 buildx 来进行构建，但这个部分官方按照插件分发，即使版本足够也可能无法使用，所以有具体的判断
# 为保兼容性，项目维护两个 Dockerfile
DOCKER_VERSION=$(docker version -f '{{.Client.Version}}')
BUILDX_SUPPORT_VERSION=18.09

echo "Build 并 Push 镜像 ${IMAGE}"

DOCKERFILE=${WORKSPACE_DIR}/Dockerfile
if [[ $(echo "${BUILDX_SUPPORT_VERSION} ${DOCKER_VERSION}" | tr " " "\n" | sort -V | head -n 1) != ${DOCKER_VERSION} ]]; then
  echo "Docker 版本 ${DOCKER_VERSION} 支持 BuildKit，使用 buildkit 文件"
  export DOCKER_BUILDKIT=1
  DOCKERFILE=${WORKSPACE_DIR}/Dockerfile.buildkit
fi

CHECK_BUILDKIT=$(docker buildx || true)

if [[ ${CHECK_BUILDKIT} =~ "BuildKit" ]]; then
    echo "使用 BuildKit buildx 命令打包"
    docker buildx build -f ${DOCKERFILE} . --tag ${IMAGE} --push
    echo "推送完毕"
else
    echo "Docker 版本 ${DOCKER_VERSION} 不支持 buildx，使用 Legacy 方案"
    docker build -f ${DOCKERFILE} . --tag ${IMAGE}
    docker push ${IMAGE}
    echo "推送完毕"
fi

# 存留版本信息
echo ${IMAGE_TAG} > ${_DEPLOY_DIR}/version.txt
