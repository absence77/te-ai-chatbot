# ---------- deps ----------
FROM public.ecr.aws/docker/library/node:20-alpine AS deps
WORKDIR /app

# Устанавливаем зависимости (используем lock-файл, если есть)
COPY package.json package-lock.json* ./
RUN npm ci

# ---------- builder ----------
FROM public.ecr.aws/docker/library/node:20-alpine AS builder
WORKDIR /app

# Копируем установленные зависимости из deps
COPY --from=deps /app/node_modules ./node_modules
# Копируем весь код приложения
COPY . .

# Собираем Next.js-приложение
RUN npm run build

# ---------- runner ----------
FROM public.ecr.aws/docker/library/node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Копируем артефакты билда и необходимые файлы
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

# Запуск прод-сервера Next.js
CMD ["npm", "run", "start"]

