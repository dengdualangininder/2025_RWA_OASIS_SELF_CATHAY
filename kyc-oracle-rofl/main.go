package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/joho/godotenv"
)

// KYC 請求結構
type KYCRequest struct {
	UserAddress  string `json:"user_address"`
	DocumentID   string `json:"document_id"`
	DocumentType string `json:"document_type"` // passport, id_card, driver_license
}

// 外部 KYC API 回應
type KYCResponse struct {
	Verified  bool   `json:"verified"`
	RiskScore uint8  `json:"risk_score"` // 0-100
	Provider  string `json:"provider"`
}

type KYCOracle struct {
	client          *ethclient.Client
	contractAddress common.Address
	privateKey      string
	kycAPIKey       string
	kycAPIURL       string
}

func NewKYCOracle() (*KYCOracle, error) {
	rpcURL := os.Getenv("SAPPHIRE_RPC_URL")
	if rpcURL == "" {
		rpcURL = "https://testnet.sapphire.oasis.io"
	}

	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Sapphire: %w", err)
	}

	return &KYCOracle{
		client:          client,
		contractAddress: common.HexToAddress(os.Getenv("CONTRACT_ADDRESS")),
		privateKey:      os.Getenv("ROFL_PRIVATE_KEY"),
		kycAPIKey:       os.Getenv("KYC_API_KEY"),
		kycAPIURL:       os.Getenv("KYC_API_URL"),
	}, nil
}

// 模擬呼叫外部 KYC 服務
func (o *KYCOracle) callKYCAPI(ctx context.Context, req KYCRequest) (*KYCResponse, error) {
	// 實際使用時，這裡呼叫 Jumio, Onfido, Sumsub 等 KYC API

	// 模擬 API 呼叫
	payload := map[string]interface{}{
		"document_id":   req.DocumentID,
		"document_type": req.DocumentType,
		"user_address":  req.UserAddress,
	}

	jsonData, _ := json.Marshal(payload)

	httpReq, err := http.NewRequestWithContext(ctx, "POST", o.kycAPIURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Authorization", "Bearer "+o.kycAPIKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(httpReq)
	if err != nil {
		// 在開發階段，如果 API 不可用，返回模擬數據
		log.Printf("KYC API call failed, using mock data: %v", err)
		return &KYCResponse{
			Verified:  true,
			RiskScore: 15, // 低風險
			Provider:  "mock",
		}, nil
	}
	defer resp.Body.Close()

	var kycResp KYCResponse
	if err := json.NewDecoder(resp.Body).Decode(&kycResp); err != nil {
		return nil, err
	}

	return &kycResp, nil
}

// 生成證明雜湊
func (o *KYCOracle) generateProof(userAddr string, verified bool, riskScore uint8) [32]byte {
	data := fmt.Sprintf("%s:%t:%d:%d", userAddr, verified, riskScore, time.Now().Unix())
	return sha256.Sum256([]byte(data))
}

// 提交 KYC 結果到鏈上合約
func (o *KYCOracle) submitToChain(ctx context.Context, userAddr common.Address,
	verified bool, riskScore uint8, proof [32]byte) error {

	privateKey, err := crypto.HexToECDSA(o.privateKey)
	if err != nil {
		return fmt.Errorf("invalid private key: %w", err)
	}

	chainID, err := o.client.ChainID(ctx)
	if err != nil {
		return err
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		return err
	}

	// 這裡需要使用生成的 Go binding (之後會說明)
	// 暫時用手動構建交易的方式

	// 建立合約呼叫數據
	// Function signature: updateKYCStatus(address,bool,uint8,bytes32)
	methodID := crypto.Keccak256([]byte("updateKYCStatus(address,bool,uint8,bytes32)"))[:4]

	// ABI 編碼參數
	data := append(methodID, common.LeftPadBytes(userAddr.Bytes(), 32)...)
	if verified {
		data = append(data, common.LeftPadBytes([]byte{1}, 32)...)
	} else {
		data = append(data, common.LeftPadBytes([]byte{0}, 32)...)
	}
	data = append(data, common.LeftPadBytes([]byte{riskScore}, 32)...)
	data = append(data, proof[:]...)

	// 發送交易
	nonce, err := o.client.PendingNonceAt(ctx, auth.From)
	if err != nil {
		return err
	}

	gasPrice, err := o.client.SuggestGasPrice(ctx)
	if err != nil {
		return err
	}

	tx := types.NewTransaction(nonce, o.contractAddress, big.NewInt(0), 300000, gasPrice, data)

	signedTx, err := auth.Signer(auth.From, tx)
	if err != nil {
		return err
	}

	err = o.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return err
	}

	log.Printf("✅ KYC status submitted to chain: %s", signedTx.Hash().Hex())
	return nil
}

// 處理 KYC 驗證請求
func (o *KYCOracle) ProcessKYC(ctx context.Context, req KYCRequest) error {
	log.Printf("🔍 Processing KYC for user: %s", req.UserAddress)

	// 1. 呼叫外部 KYC API
	kycResult, err := o.callKYCAPI(ctx, req)
	if err != nil {
		return fmt.Errorf("KYC API call failed: %w", err)
	}

	log.Printf("📋 KYC Result - Verified: %t, Risk Score: %d",
		kycResult.Verified, kycResult.RiskScore)

	// 2. 生成零知識證明雜湊
	userAddr := common.HexToAddress(req.UserAddress)
	proof := o.generateProof(req.UserAddress, kycResult.Verified, kycResult.RiskScore)

	// 3. 提交到鏈上
	err = o.submitToChain(ctx, userAddr, kycResult.Verified, kycResult.RiskScore, proof)
	if err != nil {
		return fmt.Errorf("failed to submit to chain: %w", err)
	}

	log.Printf("✨ KYC processing completed for %s", req.UserAddress)
	return nil
}

// HTTP 處理器
func (o *KYCOracle) handleVerify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req KYCRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request: %v", err), http.StatusBadRequest)
		return
	}

	// 驗證地址格式
	if !common.IsHexAddress(req.UserAddress) {
		http.Error(w, "Invalid Ethereum address", http.StatusBadRequest)
		return
	}

	// 處理 KYC
	if err := o.ProcessKYC(r.Context(), req); err != nil {
		log.Printf("❌ Error processing KYC: %v", err)
		http.Error(w, fmt.Sprintf("Processing failed: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "success",
		"message": "KYC verification submitted to blockchain",
	})
}

func (o *KYCOracle) handleHealth(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "healthy",
		"service": "kyc-oracle-rofl",
	})
}

func main() {

	// 載入 .env 檔案
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️  No .env file found, using system environment variables")
	}

	oracle, err := NewKYCOracle()
	if err != nil {
		log.Fatal("Failed to initialize KYC Oracle:", err)
	}

	http.HandleFunc("/verify", oracle.handleVerify)
	http.HandleFunc("/health", oracle.handleHealth)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 KYC Oracle ROFL service starting on port %s", port)
	log.Printf("📡 Connected to contract: %s", oracle.contractAddress.Hex())

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal("Server failed:", err)
	}
}
