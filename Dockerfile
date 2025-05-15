# docker login gitlab.domain -u username -p glpat-tokenvals
# docker buildx create --name pangolin
# docker buildx use pangolin
# docker buildx build --platform linux/arm64,linux/amd64,linux/arm/v7 --push -t gitlab.domain/trustypangolin/traefik-forward-auth:latest .

FROM --platform=${BUILDPLATFORM} golang:1.24.3-alpine AS builder

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
RUN printf "NOTE: docker build --progress=plain --no-cache --platform=<YOUR-TARGET-PLATFORM>"
RUN printf "TARGETPLATFORM=${TARGETPLATFORM}"
RUN printf "TARGETARCH=${TARGETARCH}"

# Setup
RUN mkdir -p /go/src/github.com/trustypangolin/traefik-forward-auth
WORKDIR /go/src/github.com/trustypangolin/traefik-forward-auth

# Add libraries
RUN apk add --no-cache git

# Copy & build
ADD . /go/src/github.com/trustypangolin/traefik-forward-auth/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} GO111MODULE=on go build -a -installsuffix nocgo -o /traefik-forward-auth github.com/trustypangolin/traefik-forward-auth/cmd

# Copy into scratch container
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /traefik-forward-auth ./
ENTRYPOINT ["./traefik-forward-auth"]
