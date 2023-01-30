FROM golang:1.19.5-alpine as build

ENV DRONE_VERSION=2.16.0
ENV GOPROXY=https://goproxy.cn,direct
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk update
RUN apk add -U --no-cache ca-certificates git build-base
RUN mkdir -p /src/drone && \
    cd /src/drone && \
    git clone https://gitclone.com/github.com/harness/drone.git . && \
    git checkout -b v${DRONE_VERSION}
RUN cd /src/drone/cmd/drone-server && go build -tags "nolimit" -ldflags "-extldflags \"-static\"" -o drone-server

FROM alpine:3.7

EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=false

COPY --from=build /src/drone/cmd/drone-server/drone-server /bin/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ENTRYPOINT ["/bin/drone-server"]
