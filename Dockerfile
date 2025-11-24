# ---------- deps ----------
FROM public.ecr.aws/docker/library/node:20-alpine AS deps
WORKDIR /app

# build-args для секретов
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG OPENAI_API_KEY

# пробрасываем их в ENV, чтобы next build видел process.env
ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL
ENV NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY

COPY package.json ./
RUN npm install

# ---------- builder ----------
FROM public.ecr.aws/docker/library/node:20-alpine AS builder
WORKDIR /app

# те же ARG/ENV во второй стадии
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG OPENAI_API_KEY

ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL
ENV NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY
ENV OPENAI_API_KEY=$OPENAI_API_KEY

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# ---------- runner ----------
FROM public.ecr.aws/docker/library/node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

CMD ["npm", "run", "start"]

