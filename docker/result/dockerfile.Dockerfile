FROM node:20-bookworm-slim
WORKDIR /app

COPY package*.json ./
RUN npm ci && npm cache clean --force
COPY . .
EXPOSE 4000
CMD ["node", "server.js"]
