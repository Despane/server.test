FROM node:22-alpine
WORKDIR /opt/app
COPY package*.json ./
RUN npm install
ADD . .
RUN npm run build

CMD ["npm", "start"]