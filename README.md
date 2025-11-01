# 不需信任的 KYC 預言機系統

> 使用 ROFL (Runtime Off-chain Logic) 架構實現安全、隱私保護的鏈上身份驗證系統

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Oasis Sapphire](https://img.shields.io/badge/Oasis-Sapphire-blue)](https://docs.oasis.io/dapp/sapphire/)

--- 

## 📋 目錄

- [專案簡介](#專案簡介)
- [系統架構](#系統架構)
- [技術棧](#技術棧)
- [完整流程](#完整流程)
- [系統優勢](#系統優勢)
- [快速開始](#快速開始)
- [部署指南](#部署指南)
- [使用範例](#使用範例)
- [應用場景](#應用場景)
- [技術原理](#技術原理)
- [常見問題](#常見問題)
- [License](#license)

---

## 專案簡介

本專案實作了一套**不需信任的 KYC（Know Your Customer）預言機系統**，結合區塊鏈智能合約與鏈下 ROFL 服務，在保護用戶隱私的同時，將身份驗證結果安全地記錄到區塊鏈上。

### 核心問題

傳統 KYC 系統面臨的挑戰：
- ❌ 中心化信任問題
- ❌ 隱私資料外洩風險
- ❌ 鏈上運算成本高昂
- ❌ 多平台重複驗證

### 解決方案

本系統透過 ROFL 架構：
- ✅ 鏈下處理敏感資料，保護隱私
- ✅ TEE 環境保證執行安全
- ✅ 鏈上儲存驗證結果，不可篡改
- ✅ 密碼學證明確保資料真實性

---

## 系統架構

```
┌─────────────┐
│   使用者     │
│  (錢包地址)  │
└──────┬──────┘
       │ POST /verify
       ↓
┌──────────────────────────────────┐
│     ROFL 服務 (Go)               │
│  ┌────────────────────────────┐  │
│  │  可信執行環境 (TEE)         │  │
│  │  - 接收 KYC 請求           │  │
│  │  - 呼叫 KYC API            │  │
│  │  - 產生加密證明            │  │
│  │  - 簽署並提交交易          │  │
│  └────────────────────────────┘  │
└───────┬──────────────────────────┘
        │ 呼叫 KYC API
        ↓
┌──────────────────┐      ┌──────────────────────┐
│  KYC API Mock    │      │  智能合約 (Solidity)  │
│  (Vercel)        │      │  (Oasis Sapphire)    │
│  - 身份驗證      │      │  - 儲存 KYC 狀態     │
│  - 風險評估      │←─────│  - 權限控制          │
└──────────────────┘ 驗證 │  - 公開查詢接口      │
                    結果  └──────────────────────┘
                           ↑
                           │ updateKYCStatus()
                    ROFL 簽署交易提交
```

### 目錄結構

```
test2_預言機線下KYC/
├── kyc-api-mock/              # 模擬 KYC API (Vercel 部署)
│   ├── api/
│   │   └── verify.js          # KYC 驗證邏輯
│   ├── vercel.json            # Vercel 部署配置
│   └── README.md
│
├── kyc-oracle-rofl/           # ROFL 鏈下服務 (Go)
│   ├── main.go                # 主程式
│   ├── go.mod                 # Go 依賴管理
│   ├── go.sum
│   ├── .env.example           # 環境變數範例
│   ├── Dockerfile             # Docker 容器化
│   ├── compose.yaml           # Docker Compose 配置
│   └── README.md
│
├── kyc-smart-contracts/       # 智能合約 (Solidity)
│   └── KYCOracle.sol          # KYC 預言機合約
│
└── README.md                  # 本文件
```

---

## 技術棧

### 智能合約
- **語言**: Solidity ^0.8.20
- **區塊鏈**: Oasis Sapphire (EVM 兼容)
- **功能**: 儲存 KYC 狀態、權限控制、公開查詢

### ROFL 服務
- **語言**: Go 1.21+
- **框架**: 標準 HTTP 服務
- **功能**: API 中介、證明生成、交易簽署

### KYC API
- **平台**: Vercel Serverless
- **語言**: Node.js
- **功能**: 模擬身份驗證與風險評估

---

## 完整流程

### 1. 用戶發起 KYC 請求

```
curl -X POST http://rofl-service:8080/verify \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
    "document_id": "A123456789",
    "document_type": "passport"
  }'
```

### 2. ROFL 服務處理流程

```
接收請求
  ↓
呼叫 KYC API
  ↓
獲取驗證結果 (verified: true/false, risk_score: 0-100)
  ↓
產生證明雜湊 = SHA256(user_address + verified + risk_score + timestamp)
  ↓
簽署交易 (使用 ROFL 私鑰)
  ↓
提交到智能合約 updateKYCStatus()
  ↓
返回成功訊息
```

### 3. 智能合約儲存狀態

```
struct KYCStatus {
    bool verified;        // 是否通過驗證
    uint8 riskLevel;     // 風險等級 0-100
    uint256 timestamp;   // 驗證時間戳
    bytes32 proofHash;   // 證明雜湊
}
```

### 4. 查詢 KYC 狀態

```
// 查詢是否通過驗證
bool isVerified = kycOracle.isKYCVerified(userAddress);

// 查詢完整狀態
(bool verified, uint8 riskLevel, uint256 timestamp, bytes32 proofHash) 
  = kycOracle.getKYCStatus(userAddress);
```

---

## 系統優勢

### 🔒 隱私保護
- 敏感身份資料僅在 ROFL 的 TEE 環境中處理
- KYC API 端點不對外公開
- 鏈上只儲存驗證結果，不儲存原始資料

### ⛓️ 不需信任
- TEE 硬體保證執行環境安全
- 密碼學證明確保結果真實性
- 智能合約權限控制，防止未授權更新
- 區塊鏈不可篡改特性保證資料完整性

### 💰 成本優化
- 複雜運算在鏈下執行，節省 Gas 費用
- 鏈上只儲存最終結果
- 批次處理支援（未來擴展）

### 🌐 互操作性
- EVM 兼容，可部署到多條鏈
- 標準化查詢接口，易於整合
- 支援多種身份驗證標準

---

## 快速開始

### 前置需求

- Node.js 16+
- Go 1.21+
- MetaMask 錢包
- Oasis Sapphire Testnet 測試幣

### 1. 部署 KYC API Mock

```
cd kyc-api-mock

# 安裝 Vercel CLI
npm install -g vercel

# 登入 Vercel
vercel login

# 部署
vercel --prod

# 記錄 API URL
# https://your-project.vercel.app
```

### 2. 部署智能合約

1. 打開 [Remix IDE](https://remix.ethereum.org/)
2. 新增檔案 `KYCOracle.sol`，貼上 `kyc-smart-contracts/KYCOracle.sol` 內容
3. 編譯合約（Solidity 0.8.20+）
4. 連接 MetaMask 到 Sapphire Testnet
5. 部署合約
6. **記錄合約地址**

### 3. 設定 ROFL 服務

```
cd kyc-oracle-rofl

# 複製環境變數範例
cp .env.example .env

# 編輯 .env
nano .env
```

填入配置：

```
SAPPHIRE_RPC_URL=https://testnet.sapphire.oasis.io
CONTRACT_ADDRESS=0x你的合約地址
ROFL_PRIVATE_KEY=你的私鑰(去掉0x)
KYC_API_KEY=your-api-key
KYC_API_URL=https://your-project.vercel.app/verify
PORT=8080
```

### 4. 啟動 ROFL 服務

```
# 安裝依賴
go mod tidy

# 運行服務
go run main.go

# 或使用 Docker
docker build -t kyc-oracle-rofl .
docker run -p 8080:8080 --env-file .env kyc-oracle-rofl
```

### 5. 設定合約權限

在 Remix 呼叫智能合約：

```
// 設定 ROFL 服務地址
setROFLAddress("0xROFL服務帳戶地址")
```

### 6. 測試完整流程

```
# 測試健康檢查
curl http://localhost:8080/health

# 發送 KYC 請求
curl -X POST http://localhost:8080/verify \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x你的錢包地址",
    "document_id": "TEST123",
    "document_type": "passport"
  }'
```

---

## 部署指南

### Sapphire Testnet 配置

**網路資訊**：
- **名稱**: Oasis Sapphire Testnet
- **RPC URL**: https://testnet.sapphire.oasis.io
- **Chain ID**: 23295 (0x5aff)
- **符號**: TEST
- **區塊瀏覽器**: https://testnet.explorer.sapphire.oasis.io

**取得測試幣**：
- 水龍頭: https://faucet.testnet.oasis.io/

### 環境變數說明

#### ROFL 服務 (.env)

| 變數 | 說明 | 範例 |
|------|------|------|
| `SAPPHIRE_RPC_URL` | Sapphire RPC 端點 | https://testnet.sapphire.oasis.io |
| `CONTRACT_ADDRESS` | KYC 合約地址 | 0xbb58f9Ee10cA8c56eeb036640D30112D35222D12 |
| `ROFL_PRIVATE_KEY` | ROFL 服務私鑰 (去掉 0x) | abc123...def456 |
| `KYC_API_KEY` | KYC API 金鑰 | your-secret-key |
| `KYC_API_URL` | KYC API 端點 | https://api.example.com/verify |
| `PORT` | 服務埠號 | 8080 |

#### KYC API (vercel.json)

```
{
  "env": {
    "API_KEY": "your-secret-key"
  }
}
```

---

## 使用範例

### 場景：專業投資人認證

```
// 1. 用戶提交 KYC 請求
const response = await fetch('http://rofl-service:8080/verify', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_address: userWalletAddress,
    document_id: 'A123456789',
    document_type: 'passport'
  })
});

// 2. 等待鏈上確認 (約 6 秒)
await new Promise(resolve => setTimeout(resolve, 6000));

// 3. 查詢鏈上 KYC 狀態
const kycOracle = new ethers.Contract(contractAddress, abi, provider);
const isVerified = await kycOracle.isKYCVerified(userWalletAddress);

if (isVerified) {
  console.log('✅ 用戶已通過專業投資人認證');
  // 允許存取專業投資人功能
} else {
  console.log('❌ 用戶未通過認證');
}
```

### 場景：風險等級查詢

```
const [verified, riskLevel, timestamp, proofHash] = 
  await kycOracle.getKYCStatus(userAddress);

if (verified) {
  if (riskLevel < 30) {
    console.log('🟢 低風險用戶');
  } else if (riskLevel < 70) {
    console.log('🟡 中風險用戶');
  } else {
    console.log('🔴 高風險用戶');
  }
}
```

---

## 應用場景

### 🏦 金融服務

**國泰金控範例**：
1. 客戶在 App 提交身份資料與錢包地址
2. ROFL 調用國泰內部 KYC 系統驗證
3. 驗證結果寫入 Sapphire 鏈上
4. 其他 DeFi 平台可查詢該地址的 KYC 狀態
5. 實現跨平台身份互認，減少重複驗證

### 🎮 NFT 市場

- 高價值 NFT 交易需要 KYC
- 賣家/買家驗證身份後記錄鏈上
- 平台查詢鏈上狀態決定交易權限

### 🌐 DeFi 協議

- 符合監管要求的 DeFi
- 大額交易前驗證身份
- 防洗錢 (AML) 合規

### 🎫 活動票券

- 實名制活動 NFT 票券
- 購買前需通過 KYC
- 防止黃牛與詐騙

---

## 技術原理

### 為什麼是「不需信任」？

#### 1. TEE 可信執行環境

ROFL 服務運行在硬體隔離的安全區域：
- CPU 級別的安全保護（Intel SGX / ARM TrustZone）
- 記憶體加密，外部無法讀取
- 執行過程可驗證，確保未被篡改

#### 2. 密碼學證明

```
// ROFL 產生證明雜湊
proofData := fmt.Sprintf("%s:%t:%d:%d", 
    userAddress, verified, riskScore, timestamp)
proofHash := sha256.Sum256([]byte(proofData))
```

- 雜湊函數單向性，無法反推原始資料
- 任何資料變動都會改變雜湊值
- 鏈上儲存雜湊，確保結果未被篡改

#### 3. 智能合約權限控制

```
modifier onlyROFL() {
    require(msg.sender == roflAppAddress, "Only ROFL app can call");
    _;
}
```

- 只有授權的 ROFL 地址可更新狀態
- Owner 可更換 ROFL 地址（應急機制）
- 防止未授權者偽造資料

#### 4. 區塊鏈不可篡改性

- 所有交易永久記錄在鏈上
- 任何人可驗證歷史記錄
- 透明且公開可查

---

## 常見問題

### Q1: ROFL 服務的私鑰如何保護？

**A**: 
- 私鑰儲存在 TEE 環境中，記憶體加密
- 環境變數不應提交到 Git
- 生產環境建議使用 HSM 或雲端金鑰管理服務

### Q2: 如果 ROFL 服務故障怎麼辦？

**A**:
- 智能合約 Owner 可更換 ROFL 服務地址
- 部署多個 ROFL 節點實現高可用
- 歷史資料仍保存在鏈上

### Q3: KYC 資料會上鏈嗎？

**A**:
- **不會**。只有驗證結果（通過/不通過）、風險分數和證明雜湊上鏈
- 敏感身份資料僅在 ROFL 的 TEE 環境中處理
- 符合 GDPR 和資料保護法規

### Q4: Gas 費用大概多少？

**A**:
- Sapphire Testnet 免費
- Mainnet 預估每次更新約 50,000-100,000 gas
- 實際費用取決於網路擁塞狀況

### Q5: 可以部署到其他鏈嗎？

**A**:
- 可以！合約是 EVM 兼容的
- 支援 Ethereum、Polygon、BSC、Avalanche 等
- 需調整 RPC URL 和 Chain ID

### Q6: 如何更新已驗證的用戶資料？

**A**:
- ROFL 可重複呼叫 `updateKYCStatus()`
- 新資料會覆蓋舊資料
- 建議保留歷史記錄（鏈下或使用事件日誌）

---

## 安全考量

### 🔐 私鑰管理
- ❌ 不要將私鑰提交到 Git
- ✅ 使用 `.env` 並加入 `.gitignore`
- ✅ 生產環境使用金鑰管理服務 (KMS)

### 🛡️ API 安全
- ✅ KYC API 使用 Bearer Token 驗證
- ✅ ROFL API 可增加 IP 白名單
- ✅ 限制請求頻率 (Rate Limiting)

### 📊 監控告警
- 監控 ROFL 服務可用性
- 追蹤交易失敗率
- 設定異常告警

---

## 未來擴展

### 短期 (1-3 個月)
- [ ] 支援多種身份驗證標準
- [ ] 批次處理多個 KYC 請求
- [ ] 增加錯誤重試機制
- [ ] Web UI 介面

### 中期 (3-6 個月)
- [ ] 多鏈部署支援
- [ ] 去中心化 ROFL 節點網路
- [ ] 身份驗證等級劃分
- [ ] 審計日誌系統

### 長期 (6-12 個月)
- [ ] 零知識證明整合
- [ ] 聯盟鏈跨鏈互認
- [ ] DAO 治理機制
- [ ] 商業化部署

---

## 貢獻指南

歡迎提交 Issue 和 Pull Request！

### 開發流程
1. Fork 本專案
2. 建立功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

---

## 致謝

- [Oasis Protocol](https://oasisprotocol.org/) - Sapphire 隱私計算平台
- [Ethereum](https://ethereum.org/) - 智能合約標準
- [Go Ethereum](https://geth.ethereum.org/) - Go 區塊鏈工具庫

---

## License

MIT License - 詳見 [LICENSE](LICENSE) 文件

---