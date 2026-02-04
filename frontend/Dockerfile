# ---------- Build stage ----------
FROM node:20-alpine AS build
WORKDIR /app

# Copy dependency files first (cache-friendly)
COPY app/package*.json ./
RUN npm ci

# Copy application source
COPY app/ .

# Build React app
RUN npm run build


# ---------- Runtime stage ----------
FROM nginx:stable-alpine

# Copy built static files
COPY --from=build /app/build /usr/share/nginx/html

# (Optional) use templated nginx config
# COPY nginx.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80
CMD ["nginx","-g","daemon off;"]

