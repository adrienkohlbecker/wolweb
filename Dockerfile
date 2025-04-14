# docker build -t wolweb .
FROM docker.io/golang:1.20-alpine AS builder

LABEL org.label-schema.vcs-url="https://github.com/adrienkohlbecker/wolweb" \
    org.label-schema.url="https://github.com/adrienkohlbecker/wolweb/blob/master/README.md"

RUN mkdir /wolweb
WORKDIR /wolweb

# Install Dependecies
RUN apk update && apk upgrade && \
    apk add --no-cache git && \
    git clone --branch homelab https://github.com/adrienkohlbecker/wolweb . && \
    go mod tidy && \
    go mod download

# Build Source Files
RUN go build -o wolweb .

# Create 2nd Stage final image
FROM docker.io/alpine
WORKDIR /wolweb
COPY --from=builder /wolweb/index.html .
COPY --from=builder /wolweb/wolweb .
COPY --from=builder /wolweb/devices.json .
COPY --from=builder /wolweb/config.json .
COPY --from=builder /wolweb/static ./static

RUN apk add --no-cache curl

ARG WOLWEBPORT=8089
ARG WOLWEBVDIR=/wolweb
ENV WOLWEBPORT=${WOLWEBPORT}
ENV WOLWEBVDIR=${WOLWEBVDIR}

CMD ["/wolweb/wolweb"]

EXPOSE ${WOLWEBPORT}
HEALTHCHECK --interval=5s --timeout=3s \
    CMD curl --silent --show-error --fail http://localhost:${WOLWEBPORT}/${WOLWEBVDIR}/health || exit 1
