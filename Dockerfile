FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY public/ ./public/
COPY src/ ./src/

RUN mkdir -p src/uploads/images src/uploads/panoramic

EXPOSE 5000

CMD ["node", "src/server.js"]
