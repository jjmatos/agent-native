# ---- Etapa 1: Builder ----
FROM node:24-bookworm-slim AS builder
WORKDIR /app

# Dependencias de sistema para módulos nativos (ARM64 compatible)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@10

# Copiar archivos de definición del workspace primero (mejor caché de capas)
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json .npmrc ./
COPY packages ./packages
COPY templates ./templates
# Añade aquí cualquier otro directorio necesario para la build (e.g., scripts)

# Instalación estricta y build del monorepo
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @agent-native/chat build # Ajusta el nombre del paquete si es necesario

# Crear un paquete de producción aislado (esto extrae solo las dependencias de prod)
RUN pnpm --filter @agent-native/chat --prod deploy /out

# ---- Etapa 2: Runner ----
FROM node:24-bookworm-slim AS runner
WORKDIR /app

# Solo lo mínimo para healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0
ENV NITRO_HOST=0.0.0.0
ENV NITRO_PORT=3000

# Copiar SOLO el paquete de producción y la salida compilada de Nitro
COPY --from=builder /out ./
COPY --from=builder /app/templates/chat/.output ./.output

EXPOSE 3000
VOLUME ["/app/data"]
CMD ["node", ".output/server/index.mjs"]
