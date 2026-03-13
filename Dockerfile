FROM alpine:3.21 AS build

RUN apk add --no-cache \
  binutils \
  boost-dev \
  build-base \
  clang \
  cmake \
  fmt-dev \
  openssl-dev \
  gcc \
  gmp-dev \
  luajit-dev \
  make \
  mariadb-connector-c-dev \
  pugixml-dev

COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/
WORKDIR /usr/src/forgottenserver/build
RUN cmake .. && make

FROM alpine:3.21

RUN apk add --no-cache \
  boost-iostreams \
  boost-filesystem \
  fmt \
  libssl3 \
  libcrypto3 \
  gmp \
  luajit \
  mariadb-connector-c \
  pugixml \
  netcat-openbsd

# Create a non-root user to run the server
RUN addgroup -S tfs && adduser -S tfs -G tfs

COPY --from=build /usr/src/forgottenserver/build/tfs /bin/tfs
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
COPY data /srv/data/
COPY LICENSE README.md *.dist *.sql /srv/

# Do NOT copy key.pem into the image -- mount it at runtime instead.
# Generate one with: openssl genrsa -out key.pem 2048

RUN chown -R tfs:tfs /srv

EXPOSE 7171 7172
WORKDIR /srv

HEALTHCHECK --interval=30s --timeout=3s CMD nc -z localhost 7171 || exit 1

USER tfs
ENTRYPOINT ["docker-entrypoint.sh"]
