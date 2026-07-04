FROM node:18-slim
WORKDIR /app
ENV PORT=80
COPY package*.json ./
RUN npm ci && npm cache clean --force
COPY . .
EXPOSE 80
CMD ["node", "server.js"]