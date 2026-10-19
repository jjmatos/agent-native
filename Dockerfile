# Etapa 1: Compilación
FROM node:22-alpine AS builder
WORKDIR /app

# Habilitar Corepack para usar pnpm de forma nativa
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copiar archivos de configuración de dependencias y workspace
COPY package*.json pnpm-lock.yaml* pnpm-workspace.yaml* ./

# Instalar todas las dependencias con pnpm
RUN pnpm install --frozen-lockfile || pnpm install

# Copiar el resto del código y construir la app
COPY . .
RUN pnpm build || true

# Etapa 2: Producción
FROM node:22-alpine AS runner
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist 2>/dev/null || COPY --from=builder /app/.next ./.next 2>/dev/null || COPY --from=builder /app ./

EXPOSE 3000

CMD ["pnpm", "start"]
