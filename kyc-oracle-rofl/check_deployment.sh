#!/bin/bash

# Oasis ROFL 部署檢查腳本
# 用於驗證部署前的所有必要配置

echo "=========================================="
echo "Oasis ROFL 部署檢查工具"
echo "=========================================="
echo ""

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查結果計數
PASSED=0
FAILED=0
WARNINGS=0

# 檢查函數
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

# 1. 檢查必要檔案
echo "📁 檢查必要檔案..."
echo ""

if [ -f "rofl.yaml" ]; then
    check_pass "rofl.yaml 存在"
else
    check_fail "rofl.yaml 不存在"
fi

if [ -f "compose.yaml" ]; then
    check_pass "compose.yaml 存在"
else
    check_fail "compose.yaml 不存在"
fi

if [ -f "Dockerfile" ]; then
    check_pass "Dockerfile 存在"
else
    check_fail "Dockerfile 不存在"
fi

if [ -f "main.go" ]; then
    check_pass "main.go 存在"
else
    check_fail "main.go 不存在"
fi

if [ -f "go.mod" ]; then
    check_pass "go.mod 存在"
else
    check_fail "go.mod 不存在"
fi

echo ""

# 2. 檢查環境變數
echo "🔐 檢查環境變數配置..."
echo ""

if [ -f ".env" ]; then
    check_pass ".env 檔案存在"
    
    # 載入環境變數
    set -a
    source .env
    set +a
    
    # 檢查必要變數
    if [ -n "$SAPPHIRE_RPC_URL" ]; then
        check_pass "SAPPHIRE_RPC_URL 已設置"
    else
        check_fail "SAPPHIRE_RPC_URL 未設置"
    fi
    
    if [ -n "$CONTRACT_ADDRESS" ] && [ "$CONTRACT_ADDRESS" != "0x..." ]; then
        # 驗證地址格式
        if [[ $CONTRACT_ADDRESS =~ ^0x[a-fA-F0-9]{40}$ ]]; then
            check_pass "CONTRACT_ADDRESS 已設置且格式正確"
        else
            check_fail "CONTRACT_ADDRESS 格式不正確（應為 0x 開頭的 40 字元十六進制）"
        fi
    else
        check_fail "CONTRACT_ADDRESS 未設置或為預設值"
    fi
    
    if [ -n "$ROFL_PRIVATE_KEY" ] && [ "$ROFL_PRIVATE_KEY" != "your_private_key_here_without_0x" ]; then
        # 驗證私鑰格式（不應有 0x 前綴，應為 64 字元）
        if [[ $ROFL_PRIVATE_KEY =~ ^[a-fA-F0-9]{64}$ ]]; then
            check_pass "ROFL_PRIVATE_KEY 已設置且格式正確（不含 0x）"
        else
            check_fail "ROFL_PRIVATE_KEY 格式不正確（應為 64 字元十六進制，不含 0x）"
        fi
    else
        check_fail "ROFL_PRIVATE_KEY 未設置或為預設值"
    fi
    
    if [ -n "$KYC_API_URL" ]; then
        check_pass "KYC_API_URL 已設置"
    else
        check_warn "KYC_API_URL 未設置（如果不需要傳統 KYC API 可忽略）"
    fi
    
    if [ -n "$KYC_API_KEY" ]; then
        check_pass "KYC_API_KEY 已設置"
    else
        check_warn "KYC_API_KEY 未設置（如果不需要傳統 KYC API 可忽略）"
    fi
else
    check_fail ".env 檔案不存在（請從 .env.example 複製並配置）"
fi

echo ""

# 3. 檢查 rofl.yaml 配置
echo "📋 檢查 rofl.yaml 配置..."
echo ""

if [ -f "rofl.yaml" ]; then
    # 檢查必要欄位
    if grep -q "name:" rofl.yaml; then
        check_pass "rofl.yaml 包含 name 欄位"
    else
        check_fail "rofl.yaml 缺少 name 欄位"
    fi
    
    if grep -q "tee: tdx" rofl.yaml; then
        check_pass "rofl.yaml TEE 類型設置為 TDX"
    else
        check_warn "rofl.yaml TEE 類型可能不是 TDX"
    fi
    
    if grep -q "kind: container" rofl.yaml; then
        check_pass "rofl.yaml 部署類型為 container"
    else
        check_fail "rofl.yaml 部署類型不正確"
    fi
    
    if grep -q "compose.yaml" rofl.yaml; then
        check_pass "rofl.yaml 正確引用 compose.yaml"
    else
        check_fail "rofl.yaml 未引用 compose.yaml"
    fi
    
    # 檢查 artifacts
    if grep -q "artifacts:" rofl.yaml; then
        check_pass "rofl.yaml 包含 artifacts 配置"
    else
        check_fail "rofl.yaml 缺少 artifacts 配置"
    fi
fi

echo ""

# 4. 檢查 compose.yaml 配置
echo "🐳 檢查 compose.yaml 配置..."
echo ""

if [ -f "compose.yaml" ]; then
    if grep -q "kyc-oracle" compose.yaml; then
        check_pass "compose.yaml 包含服務定義"
    else
        check_fail "compose.yaml 缺少服務定義"
    fi
    
    if grep -q "CONTRACT_ADDRESS" compose.yaml; then
        check_pass "compose.yaml 正確引用 CONTRACT_ADDRESS"
    else
        check_fail "compose.yaml 未引用 CONTRACT_ADDRESS"
    fi
    
    if grep -q "ROFL_PRIVATE_KEY" compose.yaml; then
        check_pass "compose.yaml 正確引用 ROFL_PRIVATE_KEY"
    else
        check_fail "compose.yaml 未引用 ROFL_PRIVATE_KEY"
    fi
fi

echo ""

# 5. 檢查系統依賴
echo "🛠️  檢查系統依賴..."
echo ""

if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    check_pass "Go 已安裝: $GO_VERSION"
else
    check_fail "Go 未安裝"
fi

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    check_pass "Docker 已安裝: $DOCKER_VERSION"
else
    check_fail "Docker 未安裝"
fi

if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    check_pass "Docker Compose 已安裝"
else
    check_fail "Docker Compose 未安裝"
fi

# 檢查 ROFL CLI（可選）
if command -v rofl &> /dev/null; then
    check_pass "ROFL CLI 已安裝"
else
    check_warn "ROFL CLI 未安裝（可選，用於 Oasis 網路部署）"
fi

echo ""

# 6. 檢查網路連接
echo "🌐 檢查網路連接..."
echo ""

if [ -n "$SAPPHIRE_RPC_URL" ]; then
    # 嘗試連接 RPC（超時 5 秒）
    if curl -s --max-time 5 "$SAPPHIRE_RPC_URL" > /dev/null 2>&1; then
        check_pass "可以連接到 Sapphire RPC: $SAPPHIRE_RPC_URL"
    else
        check_fail "無法連接到 Sapphire RPC: $SAPPHIRE_RPC_URL"
    fi
fi

echo ""

# 7. 檢查 Go 模組
echo "📦 檢查 Go 模組..."
echo ""

if [ -f "go.mod" ]; then
    if go mod verify &> /dev/null; then
        check_pass "Go 模組驗證通過"
    else
        check_warn "Go 模組驗證失敗（請執行 'go mod tidy'）"
    fi
fi

echo ""

# 總結
echo "=========================================="
echo "檢查結果總結"
echo "=========================================="
echo -e "${GREEN}✅ 通過: $PASSED${NC}"
echo -e "${YELLOW}⚠️  警告: $WARNINGS${NC}"
echo -e "${RED}❌ 失敗: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有必要檢查都通過！可以開始部署。${NC}"
    exit 0
else
    echo -e "${RED}⚠️  請修復上述錯誤後再進行部署。${NC}"
    exit 1
fi

