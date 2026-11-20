# Imagem da Calculadora oficial (perfil offline) para rodar dentro do cluster LIFF.
# Etapa 1: gera o banco SQLite pelos scripts Flyway oficiais e compila o JAR.
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /src
COPY pom.xml lombok.config ./
RUN mvn -B -q dependency:go-offline
COPY flyway flyway
COPY src src
RUN mkdir -p calculadora/db \
 && mvn -B -q flyway:migrate -Dflyway.configFiles=./flyway/flyway-pro.conf --errors \
 && mvn -B -q -DskipTests package \
 && ls -la calculadora/db target/*.jar

# Etapa 2: só o JRE, o JAR e o banco. O perfil offline abre ./calculadora/db relativo ao WORKDIR.
FROM eclipse-temurin:25-jre
WORKDIR /app
RUN useradd -r -u 10001 calc
COPY --from=build /src/target/api-regime-geral.jar app.jar
COPY --from=build /src/calculadora/db calculadora/db
RUN chown -R calc /app
USER 10001
EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["java", "-Dspring.profiles.active=offline", "-jar", "app.jar"]
