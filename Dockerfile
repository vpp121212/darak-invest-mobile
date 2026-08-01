FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache python3 py3-pip build-base

COPY package*.json ./
RUN npm ci --only=production

COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt --break-system-packages 2>/dev/null || pip3 install --no-cache-dir -r requirements.txt

COPY public/ ./public/
COPY src/ ./src/
COPY book_to_skill/ ./book_to_skill/

RUN mkdir -p src/uploads/images src/uploads/panoramic public/skills

EXPOSE 5000

CMD ["node", "src/server.js"]
