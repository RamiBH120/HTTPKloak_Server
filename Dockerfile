FROM golang:1.26-alpine AS builder

RUN apk --no-cache add git ca-certificates tzdata

WORKDIR /app

# 1. Copy only the go.mod file 
COPY go.mod ./

# 2. MANUALLY inject the requirement into go.mod
# This avoids the "can't request version of main module" error
RUN go mod edit -require github.com/sardanioss/httpcloak/client@v1.6.1

# 3. Now download the dependencies
RUN go mod download

# 4. Copy your sources (fixed syntax) 
COPY . .

# 5. Build the server binary 
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o httpcloak-server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/
COPY --from=builder /app/httpcloak-server .

EXPOSE 7878
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:7878/health || exit 1
CMD ["./httpcloak-server"]
