# Etapa 1: Compilación
FROM node:22-alpine AS builder
WORKDIR /app

# Instalar dependencias nativas para compilar canvas y módulos C++
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

# Activar pnpm nativo mediante Corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copiar el código fuente completo (incluye scripts/ y pnpm-workspace.yaml)
COPY . .

# Instalar dependencias del proyecto
RUN pnpm install --no-frozen-lockfile

# Compilar la aplicación
RUN pnpm build || true

# Etapa 2: Producción
FROM node:22-alpine AS runner
WORKDIR /app

# Instalar runtime libraries nativas necesarias en producción
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

CMD ["pnpm", "start"]
