# Etapa 1: Compilación
FROM node:22-alpine AS builder
WORKDIR /app

RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    cairo-dev \
    pango-dev \
    jpeg-dev \
    giflib-dev \
    librsvg-dev \
    pixman-dev

RUN corepack enable && corepack prepare pnpm@latest --activate

COPY . .

# Desactivar restricción de producción para instalar devDependencies
ENV NODE_ENV=development
RUN pnpm install --no-frozen-lockfile

# Forzar la compilación de producción
RUN pnpm build

# Etapa 2: Producción
FROM node:22-alpine AS runner
WORKDIR /app

RUN apk add --no-cache \
    cairo \
    pango \
    jpeg \
    giflib \
    librsvg \
    pixman

RUN corepack enable && corepack prepare pnpm@latest --activate

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app /app

EXPOSE 3000

# Script de arranque en cadena buscando la salida real de la build
CMD ["sh", "-c", "node dist/index.mjs || node dist/index.js || node .agent-native/server.js || pnpm start"]
