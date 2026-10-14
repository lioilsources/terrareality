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

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=build /out/ /app/
ENV APP_ENV=prod LOG_FORMAT=json HTTP_ADDR=:8080
EXPOSE 8080
USER nonroot
CMD ["/app/api"]
