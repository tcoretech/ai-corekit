FROM node:lts-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ENV PORT=3000
EXPOSE 3000
# Attempt to build if script exists
RUN npm run build --if-present
# Smart start command: Prefer 'start', then 'preview' (Vite), then 'dev'
CMD ["sh", "-c", "if grep -q '\"start\":' package.json; then npm start; elif grep -q '\"preview\":' package.json; then npm run preview -- --host --port $PORT; else echo 'No start/preview script found, trying dev...'; npm run dev -- --host --port $PORT; fi"]
