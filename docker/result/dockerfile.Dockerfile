FROM node:18-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /usr/local/app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]