FROM public.ecr.aws/docker/library/node:20-alpine

WORKDIR /app

# Создаём простой HTTP-сервер
RUN echo "const http = require('http'); \
const server = http.createServer((req, res) => { \
  res.writeHead(200, { 'Content-Type': 'text/plain' }); \
  res.end('te-ai-chatbot is running on ECS Fargate\\n'); \
}); \
server.listen(3000, '0.0.0.0', () => { \
  console.log('Server started on port 3000'); \
});" > server.js

EXPOSE 3000

# ВАЖНО: без слэшей, это JSON-массив
CMD ["node", "server.js"]

