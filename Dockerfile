# 1️⃣ Build stage
FROM node:22-alpine AS build

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build


# 2️⃣ Runtime stage (NGINX)
FROM nginx:alpine

# Remove default NGINX page
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos do build do Vite
COPY --from=build /app/dist /usr/share/nginx/html

# Copia configuração personalizada (opcional, caso queira SPA friendly routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
