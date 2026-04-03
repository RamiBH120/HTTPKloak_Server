FROM golang:1.26-alpine AS builder

# Git is required for 'go get' to work with GitHub
RUN apk --no-cache add git ca-certificates tzdata

WORKDIR /app

# 1. Copy your mod files
COPY go.mod go.sum* ./

# 2. FORCE Go to fetch the missing client package
# This solves the "no required module provides package" error
RUN go get github.com/sardanioss/httpcloak/client

# 3. Download all other dependencies
RUN go mod download

# 4. Copy your source code 
# Fixed the syntax error from your original file 
COPY . .

# 5. Build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .

EXPOSE 7878

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:7878/health || exit 1

CMD ["./httpcloak-server"]
