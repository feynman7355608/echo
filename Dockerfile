ARG MAVEN_IMAGE=maven:3-adoptopenjdk-11
ARG MAVEN_RUNTIME=adoptopenjdk:11-jre-hotspot

# -----------------------------------------------------------------------------
# Build 构建
# -----------------------------------------------------------------------------
FROM ${MAVEN_IMAGE} AS build

WORKDIR /application

COPY build/settings.xml /usr/share/maven/ref/settings-docker.xml

# pre dependency，需要按照项目结构，将所有的 pom.xml 都复制进去
COPY pom.xml ./pom.xml
RUN mvn -B -f /application/pom.xml -s /usr/share/maven/ref/settings-docker.xml dependency:resolve

# build
COPY src /application/src
RUN mvn -f /application/pom.xml -s /usr/share/maven/ref/settings-docker.xml clean package -DskipTests

# -----------------------------------------------------------------------------
# spring-boot unpacker
# -----------------------------------------------------------------------------
FROM ${MAVEN_RUNTIME} as unpacker

WORKDIR application

ARG JAR_FILE=/application/target/*.jar
COPY  --from=build ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract

# -----------------------------------------------------------------------------
# Runtime
# -----------------------------------------------------------------------------
FROM ${MAVEN_RUNTIME}

LABEL maintainer="Mark Zhou <zz.mark06@gmail.com>"

# 支持的环境变量：
# - NAME           应用名称
# - JAVA_OPTS      jvm 参数
# - JAVA_AGENT     jvm agent
ARG NAME
ARG JAVA_OPTS
ARG JAVA_AGENT

WORKDIR /application

# COPY --from=build target/*.jar ./app.jar

# 以下四行为 springboot 分层
# https://docs.spring.io/spring-boot/docs/2.3.0.RELEASE/reference/html/spring-boot-features.html#writing-the-dockerfile
# https://docs.spring.io/spring-boot/docs/2.4.0/reference/htmlsingle/#boot-features-container-images
# https://docs.spring.io/spring-boot/docs/2.5.3/reference/htmlsingle/#features.container-images
COPY --from=unpacker application/dependencies/ ./
COPY --from=unpacker application/spring-boot-loader/ ./
COPY --from=unpacker application/snapshot-dependencies/ ./
COPY --from=unpacker application/application/ ./

# add startup.sh，为了防止换行符，后边有转换 CRLF -> LF ，因此这个文件必须最后加入，不然上边的 extract 就失去了意义
COPY build/startup-springboot.sh ./startup-springboot.sh
RUN sed -i $'s/\r$//' startup-springboot.sh

CMD ["sh", "startup-springboot.sh"]

# 60001 springmvc, 60002 spring-actuator
EXPOSE 60001
EXPOSE 60002
