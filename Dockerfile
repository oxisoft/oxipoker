# Oxi Poker server image: the Go binary with the Flutter web client embedded.
#
# `docker build .` alone embeds the placeholder page from
# server/internal/webapp/dist. Release builds pass the real web client:
#
#   (cd app && flutter build web --release)
#   docker build --build-context webapp=app/build/web .
#
# which shadows the `webapp` stage below. One Dockerfile for both, so they
# cannot drift. The web bundle is architecture-independent and is built once.
FROM scratch AS webapp
COPY server/internal/webapp/dist/ /

# The builder runs on the native platform and Go cross-compiles (CGO off), so
# neither amd64 nor arm64 needs emulation. Pinned to a patch release, matching
# go.mod, so a scanner finding maps to one line here.
FROM --platform=$BUILDPLATFORM golang:1.27.4-alpine AS builder
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
RUN apk add --no-cache ca-certificates
WORKDIR /src
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server/ ./
COPY --from=webapp / ./internal/webapp/dist/
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -p 4 \
    -ldflags "-s -w -X github.com/oxisoft/oxipoker/server/internal/version.Version=${VERSION}" \
    -o /out/oxipoker ./cmd/oxipoker
RUN echo 'oxipoker:x:1000:1000:Oxi Poker:/app:/sbin/nologin' > /out/passwd && mkdir -p /out/empty

# scratch: a static binary needs no OS, and an OS is only a package list to
# patch. No shell in the image; debug with `docker logs`.
FROM scratch
ARG VERSION=dev
LABEL org.opencontainers.image.title="Oxi Poker" \
      org.opencontainers.image.description="Self-hosted No-Limit Hold'em for friends: game, chat, voice and video" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.vendor="OxiSoft" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      org.opencontainers.image.source="https://github.com/oxisoft/oxipoker"
COPY --from=builder /out/passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
WORKDIR /app
COPY --from=builder --chown=1000:1000 /out/oxipoker /app/oxipoker
COPY --from=builder --chown=1000:1000 /out/empty /app/data
COPY --from=builder --chown=1000:1000 /out/empty /tmp
USER 1000:1000
ENV PORT=8080 \
    DATA_DIR=/app/data
VOLUME ["/app/data"]
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/app/oxipoker", "-healthcheck"]
ENTRYPOINT ["/app/oxipoker"]
