FROM golang:1.26-alpine AS builder

RUN apk --no-cache add git ca-certificates tzdata

WORKDIR /app

COPY go.mod ./

RUN go get github.com/sardanioss/httpcloak@v1.6.1

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server ./cmd/server
