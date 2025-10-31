# 使用官方 Go 映像作為建置階段
FROM golang:1.21-alpine AS builder

# 安裝必要工具
RUN apk add --no-cache git ca-certificates

# 設定工作目錄
WORKDIR /app

# 複製 go mod 檔案
COPY go.mod go.sum ./

# 下載依賴
RUN go mod download

# 複製源代碼
COPY . .

# 建置應用程式
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o kyc-oracle-rofl .

# 使用輕量級映像作為運行階段
FROM alpine:latest

# 安裝 CA 證書（HTTPS 需要）
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# 從建置階段複製執行檔
COPY --from=builder /app/kyc-oracle-rofl .

# 暴露端口
EXPOSE 8080

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 運行應用程式
CMD ["./kyc-oracle-rofl"]
