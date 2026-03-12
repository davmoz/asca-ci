FROM alpine:3.19 AS build

# crypto++-dev is in edge/testing
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
  binutils \
  boost-dev \
  build-base \
  clang \
  cmake \
  crypto++-dev \
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

FROM alpine:3.19

# crypto++ is in edge/testing
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
  boost-iostreams \
  boost-system \
  boost-filesystem \
  crypto++ \
  gmp \
  luajit \
  mariadb-connector-c \
  pugixml \
  curl

RUN ln -s /usr/lib/libcryptopp.so /usr/lib/libcryptopp.so.5.6

# Create a non-root user to run the server
RUN addgroup -S tfs && adduser -S tfs -G tfs

COPY --from=build /usr/src/forgottenserver/build/tfs /bin/tfs
COPY data /srv/data/
COPY LICENSE README.md *.dist *.sql /srv/

# Do NOT copy key.pem into the image -- mount it at runtime instead.
# Generate one with: openssl genrsa -out key.pem 2048

RUN chown -R tfs:tfs /srv

EXPOSE 7171 7172
WORKDIR /srv
VOLUME /srv

# Health check: verify the status protocol responds on port 7171
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -sf http://localhost:7171/ || exit 1

USER tfs
ENTRYPOINT ["/bin/tfs"]
