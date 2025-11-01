export default async function handler(req, res) {
  // 設定 CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { user_address, document_id, document_type } = req.body;

    if (!user_address || !document_id) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    console.log('🏦 Traditional KYC API 驗證');
    console.log('   用戶:', user_address);
    console.log('   文件:', document_id);

    // 模擬信用評分（基於地址最後一位數字）
    const lastChar = user_address.slice(-1).toLowerCase();
    const baseScore = parseInt(lastChar, 16) * 50;
    const creditScore = Math.min(baseScore + 300, 850);

    // 模擬就業狀態
    const employmentStatuses = ['employed', 'self_employed', 'unemployed', 'student'];
    const employmentStatus = employmentStatuses[parseInt(lastChar, 16) % 4];

    // 模擬地址驗證
    const addressVerified = parseInt(lastChar, 16) > 5;

    // 計算風險分數
    let riskScore = 0;
    
    if (creditScore < 500) {
      riskScore += 30;
    } else if (creditScore < 650) {
      riskScore += 15;
    } else if (creditScore < 750) {
      riskScore += 5;
    }

    if (employmentStatus === 'unemployed') {
      riskScore += 25;
    } else if (employmentStatus === 'student') {
      riskScore += 10;
    }

    if (!addressVerified) {
      riskScore += 20;
    }

    const result = {
      verified: riskScore < 50,
      credit_score: creditScore,
      employment_status: employmentStatus,
      address_verified: addressVerified,
      risk_score: Math.min(riskScore, 100),
      provider: 'MockKYC',
      timestamp: new Date().toISOString(),
    };

    console.log('✅ 驗證完成');
    console.log('   信用分數:', result.credit_score);
    console.log('   就業狀態:', result.employment_status);
    console.log('   風險分數:', result.risk_score);

    return res.status(200).json(result);
  } catch (error) {
    console.error('❌ KYC API 錯誤:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
}