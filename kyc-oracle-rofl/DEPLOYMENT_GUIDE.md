# Oasis ROFL 部署指南

本指南將幫助您成功部署 Oasis ROFL KYC 預言機系統。

## 📋 前置需求檢查

### 1. 系統需求
- ✅ Go 1.21+ 已安裝
- ✅ Docker 和 Docker Compose 已安裝
- ✅ 網路連接正常（需要下載 Oasis artifacts）

### 2. Oasis ROFL CLI 工具
ROFL 部署需要使用 Oasis ROFL CLI 工具。請確認是否已安裝：

```bash
# 檢查是否已安裝 rofl CLI
which rofl

# 如果未安裝，請參考 Oasis 官方文檔安裝
# https://docs.oasis.io/dapp/sapphire/rofl
```

### 3. 環境變數配置
確認 `.env` 檔案已建立並配置正確：

```bash
cd kyc-oracle-rofl

# 如果沒有 .env 檔案，從範例複製
cp .env.example .env

# 編輯 .env 檔案，填入以下必要資訊：
# - SAPPHIRE_RPC_URL: Oasis Sapphire 網路 RPC URL
# - CONTRACT_ADDRESS: 已部署的智能合約地址
# - ROFL_PRIVATE_KEY: ROFL 服務的私鑰（不含 0x 前綴）
# - KYC_API_KEY: KYC API 金鑰
# - KYC_API_URL: KYC API 端點 URL
```

## 🔍 部署前檢查清單

### 步驟 1: 驗證 rofl.yaml 配置

檢查 `rofl.yaml` 檔案是否正確：

```bash
cat rofl.yaml
```

**必要檢查項目**：
- ✅ `name`: 服務名稱
- ✅ `version`: 版本號
- ✅ `tee: tdx`: TEE 類型（TDX = Trust Domain Extensions）
- ✅ `kind: container`: 部署類型
- ✅ `artifacts`: 所有 artifact URLs 和 checksums 正確
- ✅ `container.compose`: 指向 `compose.yaml`

### 步驟 2: 驗證 compose.yaml 配置

檢查 `compose.yaml` 檔案：

```bash
cat compose.yaml
```

**必要檢查項目**：
- ✅ 服務名稱與 rofl.yaml 一致
- ✅ 環境變數引用正確（使用 `${VARIABLE}` 格式）
- ✅ 端口映射正確（8080:8080）
- ✅ Dockerfile 路徑正確

### 步驟 3: 驗證 Dockerfile

確認 Dockerfile 存在且可正常構建：

```bash
# 測試構建（不實際運行）
docker build -t kyc-oracle-rofl:test .
```

### 步驟 4: 檢查環境變數

確認所有必要的環境變數都已設置：

```bash
# 檢查 .env 檔案是否存在
test -f .env && echo "✅ .env 存在" || echo "❌ 缺少 .env 檔案"

# 檢查必要變數（不顯示實際值）
grep -E "^(SAPPHIRE_RPC_URL|CONTRACT_ADDRESS|ROFL_PRIVATE_KEY)=" .env || echo "❌ 缺少必要環境變數"
```

## 🚀 部署步驟

### 方法 1: 使用 Oasis ROFL CLI 部署（推薦）

如果已安裝 Oasis ROFL CLI：

```bash
# 1. 確保在正確目錄
cd kyc-oracle-rofl

# 2. 驗證 rofl.yaml 配置
rofl validate rofl.yaml

# 3. 部署到 Oasis 網路
rofl deploy rofl.yaml

# 4. 檢查部署狀態
rofl status kyc-oracle-rofl
```

### 方法 2: 本地開發部署（Docker Compose）

如果只是本地測試，可以使用 Docker Compose：

```bash
# 1. 確保 .env 檔案已配置
cp .env.example .env
# 編輯 .env 填入實際值

# 2. 構建並啟動服務
docker-compose up -d --build

# 3. 檢查服務狀態
docker-compose ps

# 4. 查看日誌
docker-compose logs -f kyc-oracle
```

### 方法 3: 直接運行（開發測試）

```bash
# 1. 載入環境變數
export $(cat .env | xargs)

# 2. 安裝依賴
go mod tidy

# 3. 運行服務
go run main.go
```

## ✅ 部署後驗證

### 1. 健康檢查

```bash
# 測試健康端點
curl http://localhost:8080/health

# 預期回應：
# {
#   "status": "healthy",
#   "service": "kyc-oracle-rofl-dual",
#   "contract": "0x...",
#   "network": "Oasis Sapphire Testnet",
#   "verification_method": "Self.xyz + Traditional KYC"
# }
```

### 2. 測試驗證功能

```bash
# 發送測試驗證請求
curl -X POST http://localhost:8080/verify \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x37d8f4aC0b11D13Ab148bB9FF053F9C3379CfF2E",
    "document_id": "TEST123",
    "document_type": "passport"
  }'

# 預期回應：
# {
#   "status": "success",
#   "message": "雙軌 KYC 驗證已提交到 Oasis Sapphire"
# }
```

### 3. 檢查鏈上交易

在 Oasis Sapphire 區塊瀏覽器或使用 Remix 檢查：
- 交易是否成功提交
- 合約狀態是否更新
- 事件是否正確發射

## 🔧 常見問題排除

### 問題 1: ROFL CLI 未安裝

**錯誤訊息**：
```
command not found: rofl
```

**解決方案**：
1. 參考 [Oasis ROFL 官方文檔](https://docs.oasis.io/dapp/sapphire/rofl) 安裝 CLI
2. 或使用 Docker Compose 方法進行本地部署

### 問題 2: Artifacts 下載失敗

**錯誤訊息**：
```
failed to download artifact: ...
```

**解決方案**：
1. 檢查網路連接
2. 驗證 artifact URLs 在 `rofl.yaml` 中是否正確
3. 檢查 checksums 是否匹配

### 問題 3: 環境變數未設置

**錯誤訊息**：
```
failed to connect to Sapphire: ...
```

**解決方案**：
1. 確認 `.env` 檔案存在
2. 檢查所有必要環境變數是否已設置
3. 驗證 `SAPPHIRE_RPC_URL` 是否可訪問

### 問題 4: 合約地址無效

**錯誤訊息**：
```
invalid contract address
```

**解決方案**：
1. 確認 `CONTRACT_ADDRESS` 是有效的以太坊地址格式
2. 確認合約已部署到指定的網路
3. 確認合約地址與網路匹配（testnet/mainnet）

### 問題 5: 私鑰格式錯誤

**錯誤訊息**：
```
invalid private key
```

**解決方案**：
1. 確認 `ROFL_PRIVATE_KEY` 不包含 `0x` 前綴
2. 確認私鑰長度為 64 個十六進制字符
3. 確認私鑰對應的地址有足夠的 gas 費用

## 📝 部署檢查清單

在部署前，請確認以下項目：

- [ ] Go 1.21+ 已安裝
- [ ] Docker 和 Docker Compose 已安裝
- [ ] `.env` 檔案已建立並配置
- [ ] `SAPPHIRE_RPC_URL` 已設置
- [ ] `CONTRACT_ADDRESS` 已設置（合約已部署）
- [ ] `ROFL_PRIVATE_KEY` 已設置（不含 0x）
- [ ] `KYC_API_URL` 已設置（如果使用）
- [ ] `rofl.yaml` 配置正確
- [ ] `compose.yaml` 配置正確
- [ ] Dockerfile 可正常構建
- [ ] 網路連接正常

## 🔗 相關資源

- [Oasis ROFL 官方文檔](https://docs.oasis.io/dapp/sapphire/rofl)
- [Oasis Sapphire 網路資訊](https://docs.oasis.io/dapp/sapphire/)
- [TDX TEE 技術文檔](https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html)

## 📞 需要幫助？

如果遇到問題：
1. 檢查本指南的「常見問題排除」章節
2. 查看服務日誌：`docker-compose logs -f`
3. 參考專案 README.md
4. 聯繫 Oasis 開發者社群

---

**最後更新**: 2025年11月

