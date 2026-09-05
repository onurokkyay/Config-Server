# ---- Build stage ----
FROM eclipse-temurin:25-jdk-alpine AS build
WORKDIR /workspace

# Cache the Gradle distribution and dependencies across builds.
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle settings.gradle gradle.properties ./
RUN ./gradlew --no-daemon dependencies > /dev/null 2>&1 || true

COPY src ./src
RUN ./gradlew --no-daemon bootJar -x test

# ---- Layer extraction for image caching ----
FROM eclipse-temurin:25-jre-alpine AS extract
WORKDIR /extract
COPY --from=build /workspace/build/libs/config-server.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --layers --destination extracted

# ---- Runtime ----
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app

# git, because the config server reads its configuration from a git repository and JGit shells
# out for some operations against a local one.
RUN apk add --no-cache git \
    && addgroup -S config && adduser -S config -G config
USER config

COPY --from=extract /extract/extracted/dependencies/ ./
COPY --from=extract /extract/extracted/spring-boot-loader/ ./
COPY --from=extract /extract/extracted/snapshot-dependencies/ ./
COPY --from=extract /extract/extracted/application/ ./

EXPOSE 8888

# `java -jar app.jar`, not JarLauncher: the `tools` jarmode writes a thin jar whose manifest
# names the main class, and ships an empty spring-boot-loader/ layer. Launching through
# JarLauncher builds green and then fails to start.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
