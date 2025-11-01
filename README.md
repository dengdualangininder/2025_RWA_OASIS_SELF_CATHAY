# 不需信任的 KYC 預言機系統

> 使用 ROFL (Runtime Off-chain Logic) 架構實現安全、隱私保護的鏈上身份驗證系統

[![License: MIT](https://img.shields.io/badge(https://opensource.org/licenses/MIThttps://img.shields.io/badge(https://docs.oasis.io/dapp/sapphire/ 目錄

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

***

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

***

## 系統架構

```
┌─────────────┐
│   使用者     │
│  (錢包地址)  │
└──────┬──────┘
       │ POST /verify
       ↓
┌──────────────────────────────────┐
│     [translate:ROFL] 服務 (Go)   │
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
                    [translate:ROFL] 簽署交易提交
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
├── kyc-oracle-rofl/           # [translate:ROFL] 鏈下服務 (Go)
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

***

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

***

## 完整流程

### 1. 用戶發起 KYC 請求

```bash
curl -X POST http://localhost:8080/verify \
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

```solidity
struct KYCStatus {
    bool verified;        // 是否通過驗證
    uint8 riskLevel;      // 風險等級 0-100
    uint256 timestamp;    // 驗證時間戳
    bytes32 proofHash;    // 證明雜湊
}
```

### 4. 查詢 KYC 狀態

```solidity
bool isVerified = kycOracle.isKYCVerified(userAddress);

(bool verified, uint8 riskLevel, uint256 timestamp, bytes32 proofHash) 
  = kycOracle.getKYCStatus(userAddress);
```

***

## 系統優勢

### 🔒 隱私保護
- 鏈下 ROFL 的 TEE 環境處理敏感資料
- KYC API 保護端點不公開
- 鏈上只儲存驗證結果，不儲存身份原始資料

### ⛓️ 不需信任
- 硬體隔離的可信執行環境 (TEE)
- 密碼學證明確保資料真實性
- 智能合約控制權限防止未授權更新
- 區塊鏈保障資料不可篡改

### 💰 成本優化
- 複雜運算在鏈下執行，節省 Gas 費用
- 鏈上只儲存結果與證明雜湊

### 🌐 互操作性
- EVM 兼容智能合約
- 標準化查詢請求接口
- 易於跨鏈和跨平台集成

***

## 快速開始

### 安裝依賴、部署與啟動

｜模擬 KYC API｜部署｜

```bash
cd kyc-api-mock
npm install -g vercel
vercel login
vercel --prod
```

｜佈署智能合約｜

- 使用 Remix 編譯、部署 `KYCOracle.sol`，使用 Solidity 0.8.20+
- 連接到 Sapphire Testnet，部署並記錄合約地址

｜配置 ROFL 服務｜

編輯 `.env`，填寫：

```
SAPPHIRE_RPC_URL=https://testnet.sapphire.oasis.io
CONTRACT_ADDRESS=0x你的合約地址
ROFL_PRIVATE_KEY=你的私鑰（去掉 0x）
KYC_API_KEY=你的 API 金鑰
KYC_API_URL=https://你的 vercel-api-url/verify
PORT=8080
```

啟動：

```bash
cd kyc-oracle-rofl
go mod tidy
go run main.go
```

***

## 使用範例

### 發送 KYC 請求

```js
await fetch('http://localhost:8080/verify', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    user_address: userWalletAddress,
    document_id: 'A123456789',
    document_type: 'passport'
  })
});
```

### 查詢鏈上狀態

```js
const isVerified = await kycOracle.isKYCVerified(userWalletAddress);
const [verified, riskLevel] = await kycOracle.getKYCStatus(userWalletAddress);
console.log('狀態:', verified, '風險分數:', riskLevel);
```

***

## 應用場景

- DeFi 平台身份驗證
- NFT 市場真實交易保障
- 活動 NFT 實名制驗證
- 金融服務集團跨平台身份互認

***

## License

MIT License © 2025

詳見 [LICENSE](LICENSE)