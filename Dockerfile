FROM node:12-alpine

WORKDIR /usr/src/app

COPY ./package.json ./
COPY package-lock.json ./

RUN npm install -g serve

COPY . .

RUN ls

RUN npm run build

EXPOSE 8080

CMD serve -p $PORT -s prod