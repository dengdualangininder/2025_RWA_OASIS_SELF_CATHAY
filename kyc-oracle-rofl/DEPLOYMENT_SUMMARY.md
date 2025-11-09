# Oasis ROFL 部署檢查摘要

## ✅ 配置檔案狀態

根據檢查結果，以下配置檔案**已正確設置**：

### 1. rofl.yaml ✅
- ✅ 服務名稱：`kyc-oracle-rofl`
- ✅ 版本：`0.1.0`
- ✅ TEE 類型：`tdx` (Trust Domain Extensions)
- ✅ 部署類型：`container`
- ✅ Artifacts 配置完整（firmware, kernel, stage2, container runtime）
- ✅ 正確引用 `compose.yaml`

### 2. compose.yaml ✅
- ✅ 服務定義完整
- ✅ 環境變數引用正確
- ✅ 端口映射配置（8080:8080）
- ✅ 健康檢查配置

### 3. 程式碼檔案 ✅
- ✅ `main.go` 存在
- ✅ `go.mod` 存在
- ✅ `Dockerfile` 存在

## ⚠️ 需要完成的步驟

### 步驟 1: 建立環境變數檔案

```bash
cd kyc-oracle-rofl
cp .env.example .env
```

然後編輯 `.env` 檔案，填入以下必要資訊：

```bash
# Sapphire 連線
SAPPHIRE_RPC_URL=https://testnet.sapphire.oasis.io

# 合約地址 (從 Remix 部署後填入)
CONTRACT_ADDRESS=0x你的合約地址

# ROFL 服務的私鑰 (建立新的 MetaMask 帳戶，去掉 0x)
ROFL_PRIVATE_KEY=你的私鑰不含0x前綴

# KYC API 設定（可選，如果不需要傳統 KYC API）
KYC_API_KEY=your_api_key_here
KYC_API_URL=https://your-kyc-api.vercel.app/verify

# 伺服器端口
PORT=8080
```

### 步驟 2: 確認系統依賴

請確認以下工具已安裝：

1. **Go 1.21+**
   ```bash
   go version
   # 應該顯示 go1.21 或更高版本
   ```

2. **Docker 和 Docker Compose**
   ```bash
   docker --version
   docker-compose --version
   # 或
   docker compose version
   ```

3. **ROFL CLI**（可選，用於 Oasis 網路部署）
   - 參考 [Oasis ROFL 官方文檔](https://docs.oasis.io/dapp/sapphire/rofl) 安裝

### 步驟 3: 整理 Go 模組

```bash
cd kyc-oracle-rofl
go mod tidy
```

### 步驟 4: 部署智能合約

在部署 ROFL 服務之前，需要先部署智能合約到 Oasis Sapphire：

1. 使用 Remix 或 Hardhat 部署 `KYCOracle.sol` 合約
2. 記錄合約地址
3. 將合約地址填入 `.env` 檔案的 `CONTRACT_ADDRESS`

### 步驟 5: 授權 ROFL 節點

部署合約後，需要授權 ROFL 服務的地址：

```javascript
// 在 Remix 或 Hardhat 控制台執行
await kycOracle.authorizeNode("0x你的ROFL節點地址")
```

## 🚀 部署方式

### 方式 1: 使用 Oasis ROFL CLI（生產環境）

```bash
# 1. 驗證配置
rofl validate rofl.yaml

# 2. 部署
rofl deploy rofl.yaml

# 3. 檢查狀態
rofl status kyc-oracle-rofl
```

### 方式 2: 使用 Docker Compose（本地測試）

```bash
# 1. 確保 .env 已配置
# 2. 構建並啟動
docker-compose up -d --build

# 3. 查看日誌
docker-compose logs -f kyc-oracle

# 4. 測試健康檢查
curl http://localhost:8080/health
```

### 方式 3: 直接運行（開發測試）

```bash
# 1. 載入環境變數
export $(cat .env | xargs)

# 2. 運行服務
go run main.go
```

## 📋 部署檢查清單

在開始部署前，請確認：

- [ ] `.env` 檔案已建立並配置
- [ ] `CONTRACT_ADDRESS` 已填入（合約已部署）
- [ ] `ROFL_PRIVATE_KEY` 已填入（不含 0x 前綴）
- [ ] `SAPPHIRE_RPC_URL` 已設置
- [ ] Go 1.21+ 已安裝
- [ ] Docker 和 Docker Compose 已安裝
- [ ] 智能合約已部署
- [ ] ROFL 節點已授權
- [ ] `go mod tidy` 已執行

## 🔍 驗證部署

部署完成後，使用檢查腳本驗證：

```bash
./check_deployment.sh
```

或手動測試：

```bash
# 健康檢查
curl http://localhost:8080/health

# 測試驗證功能
curl -X POST http://localhost:8080/verify \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x37d8f4aC0b11D13Ab148bB9FF053F9C3379CfF2E",
    "document_id": "TEST123",
    "document_type": "passport"
  }'
```

## 📚 相關文檔

- 詳細部署指南：`DEPLOYMENT_GUIDE.md`
- 專案 README：`README.md`
- Oasis ROFL 官方文檔：https://docs.oasis.io/dapp/sapphire/rofl

## 🆘 需要幫助？

如果遇到問題：

1. 執行 `./check_deployment.sh` 檢查配置
2. 查看 `DEPLOYMENT_GUIDE.md` 的「常見問題排除」章節
3. 檢查服務日誌：`docker-compose logs -f`
4. 參考專案主 README.md

---

**最後更新**: 2025年11月

