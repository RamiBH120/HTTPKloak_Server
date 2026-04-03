FROM golang:1.23-alpine AS builder

RUN apk --no-cache add git ca-certificates

WORKDIR /app

# Copier tout le module (go.mod, go.sum, sources)
COPY . .

RUN GOTOOLCHAIN=off go mod download
RUN CGO_ENABLED=0 GOOS=linux GOTOOLCHAIN=off go build -a -installsuffix cgo -o httpcloak-server ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .
EXPOSE 7878
CMD ["./httpcloak-server"]
