# Etapa 1: Compilación
FROM node:22-alpine AS builder
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json pnpm-lock.yaml* yarn.lock* ./

# Instalar TODAS las dependencias (incluyendo devDependencies)
RUN npm install

# Copiar el código fuente y construir la aplicación
COPY . .
RUN npm run build || true

# Etapa 2: Producción
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist 2>/dev/null || COPY --from=builder /app/.next ./.next 2>/dev/null || COPY --from=builder /app ./

EXPOSE 3000

CMD ["npm", "start"]
