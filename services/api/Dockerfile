# Builds both binaries (api, worker) plus migrate into one small image.
# Select the process with the container command: /app/api | /app/worker | /app/migrate up
# Patch pinned to go.mod (`go`/`toolchain` 1.26.9): govulncheck runs against this toolchain.
# Build stages run on the builder's platform and cross-compile (CGO off), so an amd64 image builds
# natively on an arm64 Mac (NAS staging) and vice versa.
FROM --platform=$BUILDPLATFORM golang:1.26.9-alpine AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev COMMIT=none BUILT_AT=unknown
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath \
    -ldflags "-s -w -X github.com/terrareality/terrareality/services/api/internal/platform/buildinfo.Version=${VERSION} -X github.com/terrareality/terrareality/services/api/internal/platform/buildinfo.Commit=${COMMIT} -X github.com/terrareality/terrareality/services/api/internal/platform/buildinfo.BuiltAt=${BUILT_AT}" \
    -o /out/ ./cmd/...

# Healthcheck probe for docker compose: `probe <url>` exits 0 on a 2xx answer. A tiny static
# binary instead of busybox/curl, so the distroless image still has no shell.
FROM --platform=$BUILDPLATFORM golang:1.26.9-alpine AS probe
ARG TARGETOS TARGETARCH
RUN mkdir /p && cd /p && go mod init probe >/dev/null 2>&1 && printf '%s\n' \
    'package main' \
    'import ("net/http"; "os"; "time")' \
    'func main() {' \
    '	c := http.Client{Timeout: 4 * time.Second}' \
    '	r, err := c.Get(os.Args[1])' \
    '	if err != nil || r.StatusCode < 200 || r.StatusCode > 299 { os.Exit(1) }' \
    '}' > main.go \
 && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags "-s -w" -o /out/probe .

# Typst renders lease documents (static musl binary). The tarball is verified against the
# sha256 published on the GitHub release (bump version and both digests together).
FROM --platform=$BUILDPLATFORM alpine:3.24 AS typst
ARG TARGETARCH
ARG TYPST_VERSION=0.15.1
ARG TYPST_SHA256_X86_64=a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c
ARG TYPST_SHA256_AARCH64=5aa8d74a3d906e60ea12a66ac2f37f8eef1b14cbad7182a745e393a10c23dcee
RUN apk add --no-cache curl xz \
 && if [ "$TARGETARCH" = "arm64" ]; then arch=aarch64 sum=$TYPST_SHA256_AARCH64; else arch=x86_64 sum=$TYPST_SHA256_X86_64; fi \
 && curl -fsSL -o /tmp/typst.tar.xz "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${arch}-unknown-linux-musl.tar.xz" \
 && echo "${sum}  /tmp/typst.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/typst.tar.xz --strip-components=1 -C /usr/local/bin "typst-${arch}-unknown-linux-musl/typst" \
 && rm /tmp/typst.tar.xz

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=build /out/ /app/
COPY --from=typst /usr/local/bin/typst /usr/local/bin/typst
COPY --from=probe /out/probe /usr/local/bin/probe
ENV APP_ENV=prod LOG_FORMAT=json HTTP_ADDR=:8080 TYPST_BIN=/usr/local/bin/typst
EXPOSE 8080
USER nonroot
CMD ["/app/api"]
