# 部署用脚本

整个项目流程为
- 决定环境
- 修改配置
- 编译、打包
- push

线上机器：
- pull image
- pull _deploy
- sh _deploy/init.sh
- （SPUG环境）sh _deploy/spug.sh
- sh update.sh

日常维护脚本：
- tail.sh 查看日志
- exec.sh 进入容器
- update.sh 更新版本，仅在有tag变更后可用

## pre

决定环境后第一步，先改 _config.sh

这个步骤应该在项目计划部署时，就写入 git 中

## build

无CI/CD:

```
执行 _deploy/build.sh 打包并上传
```

有 CI/CD:

```
……有了再说
确保Docker 版本支持 BuildKit(19.03+)，执行 _deploy/build.sh 打包并上传

或者，以后有按照 CI/CD 特性 而定义的特殊流程
```

## spug 配置参考

构建脚本
```bash
TAG=${SPUG_GIT_BRANCH}-$(date +%y.%m.%d)-${SPUG_GIT_COMMIT_ID:0:7}
bash _deploy/build.sh ${TAG}
```

部署脚本
```bash
echo "IMAGE: $(<version.txt)"

sh _deploy/init.sh
sh _deploy/spug.sh
sh update.sh
```

## TODO:

- 发布流程中，docker pull 失败的 err 被吃了
- 配置中心的内容，需要重新部署才能触发。可能会涉及以下问题
  1. 同版本部署，是否可行，若可行，部署时执行脚本生成 application.yml 即可
  2.

- 日志输出，要考虑到 docker-compose.yml.template 中

- 提供 arthas，使用 WebConsole 并提供一个脚本一键连接，
  - 提供一个 sh 脚本，一键启动，还有问题没解决
  ```sh
  # 将容器的端口临时暴露到哪里
  # 端口映射
  iptables -t nat -A DOCKER -p tcp --dport <容器外部端口> -j DNAT --to-destination <容器ip>:<容器内部端口>
  # 取消端口映射规则
  iptables -t nat -D DOCKER -p tcp -d 0/0 --dport <容器外部端口> -j DNAT --to-destination <容器ip>:<容器内部端口>
  docker-compose exec ${SERVICE_NAME} java -jar arthas-boot.jar  --target-ip 0.0.0.0 
  ```
  - 或者，使用服务 Arthas Tunnel 服务

- 怎么配合网关上下线切流，需要脚本控制，计划使用 Haproxy 方案，机器太少暂且搁置
