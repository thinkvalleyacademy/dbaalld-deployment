# ---------- Build stage ----------
FROM node:20-alpine AS build
WORKDIR /app

# 👇 build-time profile
ARG REACT_APP_PROFILE=dev
ENV REACT_APP_PROFILE=${REACT_APP_PROFILE}

COPY app/package*.json ./
RUN npm ci

COPY app/ .

# Optional: log it clearly
RUN echo "[BUILD INFO] REACT_APP_PROFILE = ${REACT_APP_PROFILE}"

RUN npm run build


# ---------- Runtime stage ----------
FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
EXPOSE 80
CMD ["nginx","-g","daemon off;"]

