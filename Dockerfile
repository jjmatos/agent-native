FROM oven/bun:1.2-alpine AS base
WORKDIR /app

# Copiar solo el package.json (y bun.lockb si existe) ignorando pnpm-lock.yaml
COPY package.json bun.lockb* ./

# Instalar dependencias con Bun omitiendo lockfiles externos
RUN bun install --no-save

# Copiar todo el código fuente
COPY . .

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Arrancar la aplicación directamente con Bun
CMD ["bun", "run", "src/index.ts"]
