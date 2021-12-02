### ---------------------------------------------------
### Global Arguments
### ---------------------------------------------------
ARG NODE_VERSION="14.17.0"
ARG ALPINE_VERSION="3.13"
### ---------------------------------------------------


### ---------------------------------------------------
### Base Image
### ---------------------------------------------------
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} as base
### ---------------------------------------------------


### ---------------------------------------------------
### Development Server
### ---------------------------------------------------
FROM base as dev
RUN apk add --update bash dnsmasq curl
RUN yarn global add @quasar/cli

WORKDIR /usr/src/app
# docker build -t unfor19/awesome-pwa:dev --target dev  .
# docker run --rm -it -p 8080:8080 -p 443:443 -p 53:53/udp -v "$PWD":/usr/src/app unfor19/awesome-pwa:dev

# Application
EXPOSE 8080
EXPOSE 443

# For dnsmasq
EXPOSE 53/udp
ENTRYPOINT [ "/usr/src/app/entrypoint.dev.sh" ]
### ---------------------------------------------------


### ---------------------------------------------------
### Build App - Artifacts in /usr/src/app/dist/pwa/
### ---------------------------------------------------
FROM base as app

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json yarn.lock ./
RUN  yarn install

# Build app
COPY . .
RUN  yarn build
### ---------------------------------------------------
