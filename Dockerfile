FROM oven/bun:1.2-alpine AS base
WORKDIR /app

# Copiar package.json y el archivo de espacio de trabajo que define el "catalog:"
COPY package.json bun.lockb* pnpm-workspace.yaml* ./

# Instalar dependencias permitiendo que Bun resuelva la sintaxis "catalog:"
RUN bun install --no-save

# Copiar todo el código fuente
COPY . .

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Arrancar la aplicación directamente con Bun
CMD ["bun", "run", "src/index.ts"]
