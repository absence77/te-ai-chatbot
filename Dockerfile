# syntax=docker/dockerfile:1

# --- Сборка приложения ---
FROM node:20-alpine AS builder

WORKDIR /app

# Копируем package.json и package-lock.json (если есть)
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем остальной код
COPY . .

# Собираем приложение (если нет скрипта build — потом поправим на нужный)
RUN npm run build

# --- Продакшен-образ ---
FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

# Копируем собранное приложение из builder
COPY --from=builder /app ./

# Открываем порт (если у тебя другой, поменяешь)
EXPOSE 3000

# Команда запуска (если у тебя другой скрипт — поменяешь)
CMD ["npm", "run", "start"]

