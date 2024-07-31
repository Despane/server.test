FROM node:alpine
COPY package*.json ./
RUN npm install -g npm@latest
RUN npm cache clean --force
RUN npm install
COPY . .
EXPOSE 3000

RUN npm run build

CMD ["npm", "start"]