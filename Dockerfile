# =========================================================================
# Etapa 1: Builder (Compilación del monorepo y la app chat)
# =========================================================================
FROM node:24-bookworm-slim AS builder

WORKDIR /app

# Instalar dependencias del sistema necesarias para módulos nativos C/C++ en Linux ARM64
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar pnpm en la versión requerida por el monorepo
RUN npm install -g pnpm@10

# Copiar el código fuente completo del repositorio
COPY . .

# Solución al fallo de recap-cli: asegura la existencia de la ruta .github/workflows
RUN mkdir -p .github/workflows && touch .github/workflows/pr-visual-recap.yml

# Instalar dependencias del workspace y preconstruir paquetes
RUN pnpm install --frozen-lockfile=false

# Compilar la aplicación Chat (SSR React Router v8 + Servidor Nitro)
WORKDIR /app/templates/chat
RUN pnpm run build

# =========================================================================
# Etapa 2: Runner (Entorno de producción ligero)
# =========================================================================
FROM node:24-bookworm-slim AS runner

WORKDIR /app/templates/chat

# Herramientas mínimas para healthchecks de Coolify
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Variables de entorno de ejecución
ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0
ENV NITRO_HOST=0.0.0.0
ENV NITRO_PORT=3000

# Copiar el monorepo ya compilado
COPY --from=builder /app /app

EXPOSE 3000

# Volumen persistente para la base de datos PGlite embebida
VOLUME ["/app/templates/chat/data"]

# Arrancar el servidor Nitro de producción
CMD ["node", ".output/server/index.mjs"]
