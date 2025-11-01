import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// 儲存驗證結果
interface UserVerification {
  verified: boolean;
  nationality: string;
  is_local_resident: boolean;
  age: number;
  risk_score: number;
  timestamp: number;
}

const userVerifications = new Map<string, UserVerification>();

// 健康檢查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'kyc-self-verifier',
    version: '1.0.0',
    stored_verifications: userVerifications.size,
  });
});

// Self.xyz 驗證端點（簡化版 - Demo 用）
app.post('/api/verify', async (req, res) => {
  try {
    const { attestationId, proof, publicSignals, userContextData } = req.body;

    console.log('📋 收到驗證請求');
    if (userContextData) {
      console.log('   用戶地址:', userContextData.slice(0, 10) + '...');
    }

    // 簡化驗證邏輯（實際應該驗證零知識證明）
    // Demo 模式：假設所有請求都通過
    const isLocalResident = true;
    const nationality = 'TWN';
    const age = 30;
    
    const verification: UserVerification = {
      verified: true,
      nationality: nationality,
      is_local_resident: isLocalResident,
      age: age,
      risk_score: 10,
      timestamp: Date.now(),
    };

    if (userContextData) {
      userVerifications.set(userContextData.toLowerCase(), verification);
    }

    console.log('✅ 驗證成功');
    console.log('   國籍:', verification.nationality);
    console.log('   本國人:', verification.is_local_resident);

    return res.json({
      status: 'success',
      result: true,
      verification_summary: {
        nationality: verification.nationality,
        is_local_resident: verification.is_local_resident,
        risk_score: verification.risk_score,
      },
    });
  } catch (error) {
    console.error('❌ 驗證錯誤:', error);
    return res.json({
      status: 'error',
      result: false,
      reason: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// 查詢用戶驗證結果（供 ROFL 呼叫）
app.get('/api/user-verification/:address', (req, res) => {
  const address = req.params.address.toLowerCase();
  const verification = userVerifications.get(address);

  if (verification) {
    console.log('📖 查詢驗證結果:', address.slice(0, 10) + '...');
    return res.json({
      verified: verification.verified,
      nationality: verification.nationality,
      is_local_resident: verification.is_local_resident,
      age: verification.age,
      risk_score: verification.risk_score,
    });
  } else {
    console.log('⚠️  未找到驗證記錄:', address.slice(0, 10) + '...');
    return res.json({
      verified: false,
      nationality: 'UNKNOWN',
      is_local_resident: false,
      age: 0,
      risk_score: 50,
    });
  }
});

// 模擬驗證端點（測試用）
app.post('/api/mock-verify', (req, res) => {
  const { user_address, nationality, age } = req.body;

  if (!user_address) {
    return res.status(400).json({ error: 'user_address required' });
  }

  const isLocalResident = nationality === 'TWN';
  let riskScore = 10;
  if (!isLocalResident) riskScore += 15;
  if (age && age < 21) riskScore += 10;

  const verification: UserVerification = {
    verified: true,
    nationality: nationality || 'TWN',
    is_local_resident: isLocalResident,
    age: age || 25,
    risk_score: riskScore,
    timestamp: Date.now(),
  };

  userVerifications.set(user_address.toLowerCase(), verification);

  console.log('🧪 模擬驗證:', user_address.slice(0, 10) + '...');
  console.log('   國籍:', verification.nationality);
  console.log('   本國人:', verification.is_local_resident);
  console.log('   風險:', verification.risk_score);

  res.json({
    status: 'success',
    verification_summary: {
      nationality: verification.nationality,
      is_local_resident: verification.is_local_resident,
      risk_score: verification.risk_score,
    },
  });
});

app.listen(PORT, () => {
  console.log('🚀 KYC Self Verifier 啟動（簡化版）');
  console.log(`📡 運行於 http://localhost:${PORT}`);
  console.log('');
  console.log('=== 功能 ===');
  console.log('✅ 國籍驗證（模擬）');
  console.log('✅ 本國/非本國人判斷');
  console.log('✅ 風險分數計算');
  console.log('============');
});
