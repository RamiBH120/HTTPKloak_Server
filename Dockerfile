FROM golang:1.26-alpine AS builder

# Git is required to fetch the external 'client' package
RUN apk --no-cache add git ca-certificates tzdata

WORKDIR /app

# 1. Copy your local mod files
COPY go.mod go.sum* ./

# 2. Add the missing client dependency specifically at v1.6.1
# This ensures the 'no required module' error disappears
RUN go get github.com/sardanioss/httpcloak/client@v1.6.1

# 3. Download the rest of the requirements
RUN go mod download

# 4. Copy your source code (Fixed syntax: COPY . .)
COPY . .

# 5. Build the server
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/httpcloak-server .

EXPOSE 7878

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:7878/health || exit 1

CMD ["./httpcloak-server"]
