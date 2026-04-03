FROM golang:1.22-alpine AS builder

RUN apk --no-cache add git ca-certificates

WORKDIR /app

# Copier le code source httpcloak local
COPY httpcloak-main/ ./httpcloak-main/

# Copier le serveur
COPY main.go .
COPY go.mod .

# Remplacer l'import distant par le code local
RUN go mod edit -replace github.com/sardanioss/httpcloak=./httpcloak-main
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server .

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .
EXPOSE 7878
CMD ["./httpcloak-server"]
