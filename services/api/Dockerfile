# Builds both binaries (api, worker) plus migrate into one small image.
# Select the process with the container command: /app/api | /app/worker | /app/migrate up
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev COMMIT=none BUILT_AT=unknown
RUN CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -X github.com/terrareality/terrareality/services/api/internal/platform/buildinfo.Version=${VERSION} -X github.com/terrareality/terrareality/services/api/internal/platform/buildinfo.Commit=${COMMIT} -X github.com/terrareality/terrareality/services/api/internal/platform/buildinfo.BuiltAt=${BUILT_AT}" \
    -o /out/ ./cmd/...

# Typst renders lease documents (static musl binary).
FROM alpine:3.22 AS typst
ARG TARGETARCH
ARG TYPST_VERSION=0.15.1
RUN apk add --no-cache curl xz \
 && arch=$([ "$TARGETARCH" = "arm64" ] && echo aarch64 || echo x86_64) \
 && curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${arch}-unknown-linux-musl.tar.xz" \
    | tar -xJ --strip-components=1 -C /usr/local/bin "typst-${arch}-unknown-linux-musl/typst"

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=build /out/ /app/
COPY --from=typst /usr/local/bin/typst /usr/local/bin/typst
ENV APP_ENV=prod LOG_FORMAT=json HTTP_ADDR=:8080 TYPST_BIN=/usr/local/bin/typst
EXPOSE 8080
USER nonroot
CMD ["/app/api"]
