FROM golang:1.22-alpine AS builder

RUN apk --no-cache add git ca-certificates

WORKDIR /app

# Copier tout le module (go.mod, go.sum, sources)
COPY . .

# go 1.26 dans go.mod mais on build avec 1.22 : forcer la toolchain
RUN go mod edit -toolchain none
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .
EXPOSE 7878
CMD ["./httpcloak-server"]
