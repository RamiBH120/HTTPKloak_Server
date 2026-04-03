FROM golang:1.26-alpine AS builder

RUN apk --no-cache add git ca-certificates tzdata

WORKDIR /app

COPY . .

RUN go work sync
RUN CGO_ENABLED=0 GOOS=linux go build -o httpcloak-server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .
EXPOSE 7878
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:7878/health || exit 1
CMD ["./httpcloak-server"]
