
# ---- Etapa 1: Build do binário nativo ---------------------------------
FROM container-registry.oracle.com/graalvm/native-image:25 AS build
WORKDIR /app

# Copia o projeto para dentro da imagem
COPY . .

# Dá permissão ao mvnw, caso necessário
RUN chmod +x mvnw

# Executa o build nativo
RUN  ./mvnw install -Dnative


# ---- Etapa 2: Imagem final (mínima, só o binário) ----------------------
FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
WORKDIR /work/

# Ajusta permissões e diretório
RUN chown 1001 /work && chmod "g+rwX" /work && chown 1001:root /work

# Copia o binário nativo gerado na etapa anterior
COPY --from=build --chown=1001:root --chmod=0755 /app/target/*-runner /work/application


EXPOSE ${PORT}

USER 1001

ENTRYPOINT ["/bin/sh", "-c", "./application -Dquarkus.http.host=0.0.0.0 -Dquarkus.http.port=${PORT}"]
