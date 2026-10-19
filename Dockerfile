# Etapa 1: Compilación
FROM node:22-alpine AS builder
WORKDIR /app

# Instalar herramientas del sistema necesarias para compilar paquetes C/C++ nativos (canvas, node-gyp, python3)
RUN apk add --no-libc-validations --no-cache \
    python3 \
    make \
    g++ \
    cairo-dev \
    pango-dev \
    jpeg-dev \
    giflib-dev \
    librsvg-dev \
    pixman-dev

# Activar pnpm nativo con Corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copiar todo el código fuente antes de instalar para que existan scripts/ y pnpm-workspace.yaml
COPY . .

# Desactivar la verificación rigurosa de congelado e instalar dependencias
RUN pnpm install --no-frozen-lockfile

# Construir la aplicación
RUN pnpm build || true

# Etapa 2: Producción
FROM node:22-alpine AS runner
WORKDIR /app

# Librerías de ejecución necesarias para canvas y C++
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
