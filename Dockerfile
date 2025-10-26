#
## ---- Etapa 1: Build do binário nativo ---------------------------------
#FROM container-registry.oracle.com/graalvm/native-image:25 AS build
#WORKDIR /app
#
## Copia o projeto para dentro da imagem
#COPY . .
#
## Dá permissão ao mvnw, caso necessário
#RUN chmod +x mvnw
#
## Executa o build nativo
#RUN  ./mvnw install -Dnative
#
#
## ---- Etapa 2: Imagem final (mínima, só o binário) ----------------------
#FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
#WORKDIR /work/
#
## Ajusta permissões e diretório
#RUN chown 1001 /work && chmod "g+rwX" /work && chown 1001:root /work
#
## Copia o binário nativo gerado na etapa anterior
#COPY --from=build --chown=1001:root --chmod=0755 /app/target/*-runner /work/application
#
#
#EXPOSE ${PORT}
#
#USER 1001
#
#ENTRYPOINT ["/bin/sh", "-c", "./application -Dquarkus.http.host=0.0.0.0 -Dquarkus.http.port=${PORT}"]

## Stage 1 : build with maven builder image with native capabilities
FROM quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-21 AS build
COPY --chown=quarkus:quarkus --chmod=0755 mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
COPY --chown=quarkus:quarkus pom.xml /code/
USER quarkus
WORKDIR /code
RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.8.1:go-offline
COPY src /code/src
RUN ./mvnw package -Dnative

## Stage 2 : create the docker final image
FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
WORKDIR /work/
COPY --from=build /code/target/*-runner /work/application

# set up permissions for user `1001`
RUN chmod 775 /work /work/application \
  && chown -R 1001 /work \
  && chmod -R "g+rwX" /work \
  && chown -R 1001:root /work

EXPOSE ${PORT}

USER 1001

ENTRYPOINT ["/bin/sh", "-c", "./application -Dquarkus.http.host=0.0.0.0 -Dquarkus.http.port=${PORT}"]