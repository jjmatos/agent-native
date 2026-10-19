# =========================================================================
# Etapa 1: Builder (Compilación del monorepo y la app chat)
# =========================================================================
FROM node:24-bookworm-slim AS builder

WORKDIR /app

# Dependencias del sistema para módulos nativos
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@10

# Copiar manifiestos e instalar con lockfile congelado
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json .npmrc ./
COPY packages ./packages
COPY templates ./templates
# (Ajusta los COPY según tu estructura real; la idea es copiar lo necesario antes del build)

RUN pnpm install --frozen-lockfile

# Compilar la app Chat
WORKDIR /app/templates/chat
RUN pnpm run build

# Crear un paquete de producción aislado solo con dependencias de producción
# Requiere "inject-workspace-packages=true" en .npmrc
WORKDIR /app
RUN pnpm --filter @agent-native/chat --prod deploy /out

# =========================================================================
# Etapa 2: Runner (Entorno de producción ligero)
# =========================================================================
FROM node:24-bookworm-slim AS runner

WORKDIR /app

# Solo curl para healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0
ENV NITRO_HOST=0.0.0.0
ENV NITRO_PORT=3000

# Copiar SOLO el paquete de producción (node_modules aislado + código de la app)
COPY --from=builder /out ./

# Copiar la salida compilada de Nitro desde el builder
# (pnpm deploy copia el código fuente, pero Nitro genera .output en la etapa de build)
COPY --from=builder /app/templates/chat/.output ./.output

EXPOSE 3000
VOLUME ["/app/data"]
CMD ["node", ".output/server/index.mjs"]
