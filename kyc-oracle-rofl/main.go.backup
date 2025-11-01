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
	DocumentType string `json:"document_type"`
}

// Self.xyz 驗證結果
type SelfVerificationResult struct {
	Verified        bool   `json:"verified"`
	Nationality     string `json:"nationality"`
	IsLocalResident bool   `json:"is_local_resident"` // 是否本國人
	Age             int    `json:"age"`
	RiskScore       uint8  `json:"risk_score"`
}

// 傳統 KYC API 回應
type TraditionalKYCResult struct {
	Verified         bool   `json:"verified"`
	CreditScore      int    `json:"credit_score"`
	EmploymentStatus string `json:"employment_status"`
	AddressVerified  bool   `json:"address_verified"`
	RiskScore        uint8  `json:"risk_score"`
}

// 合併的驗證結果
type CombinedKYCResult struct {
	SelfVerified        bool
	TraditionalVerified bool
	FinalVerified       bool
	TotalRiskScore      uint8
	Nationality         string
	IsLocalResident     bool
	CreditScore         int
	EmploymentStatus    string
	AddressVerified     bool
	VerificationMethod  string
}

type KYCOracle struct {
	client          *ethclient.Client
	contractAddress common.Address
	privateKey      string
	kycAPIKey       string
	kycAPIURL       string
	selfAPIURL      string
}

func NewKYCOracle() (*KYCOracle, error) {
	log.Println("=== Oasis ROFL 雙軌 KYC 驗證系統 ===")

	rpcURL := os.Getenv("SAPPHIRE_RPC_URL")
	if rpcURL == "" {
		rpcURL = "https://testnet.sapphire.oasis.io"
	}

	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Sapphire: %w", err)
	}

	log.Println("✅ [Sapphire-ROFL] 連接到 Oasis Sapphire Testnet")

	privateKey := os.Getenv("ROFL_PRIVATE_KEY")
	kycAPIKey := os.Getenv("KYC_API_KEY")
	kycAPIURL := os.Getenv("KYC_API_URL")
	selfAPIURL := os.Getenv("SELF_API_URL")

	if selfAPIURL == "" {
		selfAPIURL = "http://localhost:3001"
	}

	oracle := &KYCOracle{
		client:          client,
		contractAddress: common.HexToAddress(os.Getenv("CONTRACT_ADDRESS")),
		privateKey:      privateKey,
		kycAPIKey:       kycAPIKey,
		kycAPIURL:       kycAPIURL,
		selfAPIURL:      selfAPIURL,
	}

	log.Println("✅ [雙軌驗證] Self.xyz + 傳統 KYC API")
	log.Printf("   - Self API: %s", selfAPIURL)
	log.Printf("   - KYC API: %s", kycAPIURL)

	return oracle, nil
}

// 呼叫 Self.xyz API (國籍驗證)
func (o *KYCOracle) callSelfAPI(ctx context.Context, userAddress string) (*SelfVerificationResult, error) {
	log.Printf("📱 [Self.xyz] 查詢國籍與身份資訊...")

	// 這裡應該從你的資料庫查詢用戶的 Self 驗證結果
	// 或者從 Self 的 callback 端點取得
	url := fmt.Sprintf("%s/api/user-verification/%s", o.selfAPIURL, userAddress)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("⚠️  Self API 無法連接，跳過國籍驗證")
		return &SelfVerificationResult{
			Verified:        false,
			Nationality:     "UNKNOWN",
			IsLocalResident: false,
			RiskScore:       50,
		}, nil
	}
	defer resp.Body.Close()

	var result SelfVerificationResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	log.Printf("✅ [Self.xyz] 國籍: %s, 本國人: %t", result.Nationality, result.IsLocalResident)
	return &result, nil
}

// 呼叫傳統 KYC API (信用、就業等)
func (o *KYCOracle) callTraditionalKYCAPI(ctx context.Context, req KYCRequest) (*TraditionalKYCResult, error) {
	log.Printf("🏦 [Traditional KYC] 查詢信用與就業資訊...")

	payload := map[string]interface{}{
		"user_address":  req.UserAddress,
		"document_id":   req.DocumentID,
		"document_type": req.DocumentType,
	}

	jsonData, _ := json.Marshal(payload)

	httpReq, err := http.NewRequestWithContext(ctx, "POST", o.kycAPIURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Authorization", "Bearer "+o.kycAPIKey)
	httpReq.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("Traditional KYC API call failed: %w", err)
	}
	defer resp.Body.Close()

	var result TraditionalKYCResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	log.Printf("✅ [Traditional KYC] 信用分數: %d, 就業: %s", result.CreditScore, result.EmploymentStatus)
	return &result, nil
}

// 合併兩個驗證結果
func (o *KYCOracle) combineResults(selfResult *SelfVerificationResult, traditionalResult *TraditionalKYCResult) *CombinedKYCResult {
	log.Println("🔀 [合併結果] 計算總體風險分數...")

	combined := &CombinedKYCResult{
		SelfVerified:        selfResult.Verified,
		TraditionalVerified: traditionalResult.Verified,
		Nationality:         selfResult.Nationality,
		IsLocalResident:     selfResult.IsLocalResident,
		CreditScore:         traditionalResult.CreditScore,
		EmploymentStatus:    traditionalResult.EmploymentStatus,
		AddressVerified:     traditionalResult.AddressVerified,
	}

	// 決定最終驗證狀態
	combined.FinalVerified = selfResult.Verified && traditionalResult.Verified

	// 計算總體風險分數 (加權平均)
	// Self 佔 40%, Traditional KYC 佔 60%
	totalRisk := (uint8(float64(selfResult.RiskScore)*0.4) + uint8(float64(traditionalResult.RiskScore)*0.6))

	// 本國人降低風險
	if selfResult.IsLocalResident {
		if totalRisk > 10 {
			totalRisk -= 10
		}
	} else {
		// 非本國人提高風險
		totalRisk += 15
	}

	combined.TotalRiskScore = totalRisk

	// 標記驗證方法
	if selfResult.Verified && traditionalResult.Verified {
		combined.VerificationMethod = "DUAL_VERIFIED"
	} else if selfResult.Verified {
		combined.VerificationMethod = "SELF_ONLY"
	} else if traditionalResult.Verified {
		combined.VerificationMethod = "TRADITIONAL_ONLY"
	} else {
		combined.VerificationMethod = "UNVERIFIED"
	}

	log.Printf("📊 [合併結果] 最終驗證: %t, 總風險: %d, 方法: %s",
		combined.FinalVerified, combined.TotalRiskScore, combined.VerificationMethod)

	return combined
}

// 生成證明雜湊
func (o *KYCOracle) generateProof(userAddr string, verified bool, riskScore uint8) [32]byte {
	data := fmt.Sprintf("%s:%t:%d:%d", userAddr, verified, riskScore, time.Now().Unix())
	return sha256.Sum256([]byte(data))
}

// 提交到鏈上
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

	methodID := crypto.Keccak256([]byte("updateKYCStatus(address,bool,uint8,bytes32)"))[:4]

	data := make([]byte, 0)
	data = append(data, methodID...)
	data = append(data, common.LeftPadBytes(userAddr.Bytes(), 32)...)

	verifiedByte := byte(0)
	if verified {
		verifiedByte = 1
	}
	data = append(data, common.LeftPadBytes([]byte{verifiedByte}, 32)...)
	data = append(data, common.LeftPadBytes([]byte{riskScore}, 32)...)
	data = append(data, proof[:]...)

	nonce, err := o.client.PendingNonceAt(ctx, auth.From)
	if err != nil {
		return err
	}

	gasPrice, err := o.client.SuggestGasPrice(ctx)
	if err != nil {
		return err
	}

	tx := types.NewTransaction(nonce, o.contractAddress, big.NewInt(0), 300000, gasPrice, data)
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		return err
	}

	err = o.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return err
	}

	log.Printf("✅ [Sapphire-ROFL] 交易已提交: %s", signedTx.Hash().Hex())
	return nil
}

// 處理 KYC 驗證請求（雙軌）
func (o *KYCOracle) ProcessKYC(ctx context.Context, req KYCRequest) error {
	log.Printf("🔍 [雙軌驗證] 開始處理: %s", req.UserAddress)

	// 並行呼叫兩個 API
	selfChan := make(chan *SelfVerificationResult)
	traditionalChan := make(chan *TraditionalKYCResult)
	errChan := make(chan error, 2)

	// Goroutine 1: Self.xyz 驗證
	go func() {
		result, err := o.callSelfAPI(ctx, req.UserAddress)
		if err != nil {
			errChan <- err
			return
		}
		selfChan <- result
	}()

	// Goroutine 2: 傳統 KYC 驗證
	go func() {
		result, err := o.callTraditionalKYCAPI(ctx, req)
		if err != nil {
			errChan <- err
			return
		}
		traditionalChan <- result
	}()

	// 等待兩個結果
	var selfResult *SelfVerificationResult
	var traditionalResult *TraditionalKYCResult

	for i := 0; i < 2; i++ {
		select {
		case result := <-selfChan:
			selfResult = result
		case result := <-traditionalChan:
			traditionalResult = result
		case err := <-errChan:
			return fmt.Errorf("verification failed: %w", err)
		case <-ctx.Done():
			return ctx.Err()
		}
	}

	// 合併結果
	combined := o.combineResults(selfResult, traditionalResult)

	// 提交到鏈上
	userAddr := common.HexToAddress(req.UserAddress)
	proof := o.generateProof(req.UserAddress, combined.FinalVerified, combined.TotalRiskScore)

	err := o.submitToChain(ctx, userAddr, combined.FinalVerified, combined.TotalRiskScore, proof)
	if err != nil {
		return fmt.Errorf("failed to submit to chain: %w", err)
	}

	log.Printf("✨ 雙軌驗證完成: %s (方法: %s)", req.UserAddress, combined.VerificationMethod)
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

	if !common.IsHexAddress(req.UserAddress) {
		http.Error(w, "Invalid Ethereum address", http.StatusBadRequest)
		return
	}

	if err := o.ProcessKYC(r.Context(), req); err != nil {
		log.Printf("❌ Error: %v", err)
		http.Error(w, fmt.Sprintf("Processing failed: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "success",
		"message": "雙軌 KYC 驗證已提交到 Oasis Sapphire",
	})
}

func (o *KYCOracle) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":              "healthy",
		"service":             "kyc-oracle-rofl-dual",
		"contract":            o.contractAddress.Hex(),
		"network":             "Oasis Sapphire Testnet",
		"verification_method": "Self.xyz + Traditional KYC",
	})
}

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️  No .env file found")
	}

	log.Println("🚀 Oasis ROFL 雙軌 KYC 驗證系統啟動...")

	oracle, err := NewKYCOracle()
	if err != nil {
		log.Fatal("初始化失敗:", err)
	}

	http.HandleFunc("/verify", oracle.handleVerify)
	http.HandleFunc("/health", oracle.handleHealth)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 服務啟動於端口 %s", port)
	log.Printf("📡 合約地址: %s", oracle.contractAddress.Hex())
	log.Println("")
	log.Println("=== 雙軌驗證系統 ===")
	log.Println("✅ Self.xyz: 國籍、年齡、護照驗證")
	log.Println("✅ Traditional KYC: 信用、就業、地址驗證")
	log.Println("✅ 智能合併風險分數")
	log.Println("====================")

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal("伺服器失敗:", err)
	}
}
