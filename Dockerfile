# -----------------------------------------------------------------------------
# Runtime
# -----------------------------------------------------------------------------
FROM adoptopenjdk:11-jre-hotspot

LABEL maintainer="Mark Zhou <zz.mark06@gmail.com>"

WORKDIR /application

# add startup.sh
COPY build/docker-entrypoint.sh ./docker-entrypoint.sh
RUN sed -i $'s/\r$//' docker-entrypoint.sh

ENTRYPOINT ["sh", "docker-entrypoint.sh"]

COPY target/*.jar ./app.jar

# 8080 springmvc, 8081 spring-actuator, 9012 jmx
EXPOSE 8080
EXPOSE 9012
