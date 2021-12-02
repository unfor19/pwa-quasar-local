### ---------------------------------------------------
### Global Arguments
### ---------------------------------------------------
ARG NODE_VERSION="14.17.0"
ARG ALPINE_VERSION="3.13"
### ---------------------------------------------------

FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} as base

### ---------------------------------------------------
### Build the application
### ---------------------------------------------------
FROM base as dev
RUN apk add --update bash dnsmasq
RUN yarn global add @quasar/cli

WORKDIR /usr/src/app
# docker run --rm -it -p 8080:8080 -p 443:443 -p 53:53/udp -v "$PWD":/usr/src/app unfor19/awesome-pwa:dev

# Application
EXPOSE 8080
EXPOSE 443

# For dnsmasq
EXPOSE 53/udp
ENTRYPOINT [ "/usr/src/app/entrypoint.dev.sh" ]
CMD ["meirg.co.il.test", "192.168.0.5"]
### ---------------------------------------------------

### ---------------------------------------------------
### Build the application
### ---------------------------------------------------
FROM base as build

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json yarn.lock ./
RUN  yarn install

# Build app
COPY . .
RUN  yarn build
### ---------------------------------------------------


### ---------------------------------------------------
### Server running the application
### ---------------------------------------------------
FROM base as server

# Create server directory
WORKDIR /app/server/

# Install server dependencies
COPY server/package.json server/yarn.lock ./
RUN  yarn install

# Copy server code
COPY server ./

# Copy app dist
WORKDIR /app/dist/
COPY    --from=build /usr/src/app/dist/ .

# This is only a declaration, it is used only when executing `docker run -P unfor19/aws-webui` on Linux OS
EXPOSE  8080

# To use the scripts in package.json
WORKDIR /app/
COPY package.json .

# Serve the application in production mode
CMD [ "yarn", "serve:prod" ]
### ---------------------------------------------------