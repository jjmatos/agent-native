# Usa la imagen oficial de Bun para ARM64
FROM oven/bun:1.2-alpine AS base
WORKDIR /app

# Copia solo archivos de dependencias
COPY package.json bun.lockb* pnpm-lock.yaml* ./

# Instala dependencias con Bun (rápido y sin compilar C++)
RUN bun install --production

# Copia el código fuente de la aplicación
COPY . .

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Punto de entrada directo del servidor
CMD ["bun", "run", "src/index.ts"]
