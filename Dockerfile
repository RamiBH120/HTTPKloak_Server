FROM golang:1.26-alpine AS builder

# Installe git pour modules externes
RUN apk --no-cache add git ca-certificates tzdata

WORKDIR /app

# Copie go.mod en 1er (cache layer)
COPY go.mod go.sum ./
RUN go mod download

# Copie sources + build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .
EXPOSE 7878
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:7878/health || exit 1
CMD ["./httpcloak-server"]
