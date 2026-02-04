# =========================
# 1️⃣ BUILD STAGE
# =========================
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /build

COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# =========================
# 2️⃣ RUNTIME STAGE
# =========================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN apk add --no-cache curl bash

COPY --from=build /build/target/alld-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8081

CMD ["sh", "-c", "\
  export SPRING_DATASOURCE_PASSWORD=$(cat /run/secrets/db_password) && \
  exec java -jar app.jar \
"]
