// 超簡單的 KYC 驗證 API
export default async function handler(req, res) {
  // 只接受 POST 請求
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // 檢查 API Key (簡單驗證)
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const apiKey = authHeader.replace('Bearer ', '');
  if (apiKey !== process.env.API_KEY) {
    return res.status(401).json({ error: 'Invalid API key' });
  }

  // 取得請求參數
  const { user_address, document_id, document_type } = req.body;

  // 簡單驗證
  if (!user_address || !document_id || !document_type) {
    return res.status(400).json({ 
      error: 'Missing required fields',
      required: ['user_address', 'document_id', 'document_type']
    });
  }

  // 模擬 KYC 驗證邏輯
  // 實際場景會呼叫真實的 KYC 服務 (Jumio, Onfido, Sumsub)
  
  // 簡單規則：
  // - 如果 document_id 包含 "FAKE"，則驗證失敗，高風險
  // - 如果 document_id 包含 "HIGH"，則驗證通過但高風險
  // - 否則驗證通過，低風險
  
  let verified = true;
  let riskScore = 10; // 預設低風險
  let reason = 'Document verified successfully';

  const docIdUpper = document_id.toUpperCase();
  
  if (docIdUpper.includes('FAKE')) {
    verified = false;
    riskScore = 95;
    reason = 'Document appears to be fraudulent';
  } else if (docIdUpper.includes('HIGH')) {
    verified = true;
    riskScore = 75;
    reason = 'Document verified but flagged for review';
  } else if (docIdUpper.includes('MEDIUM')) {
    verified = true;
    riskScore = 45;
    reason = 'Document verified with moderate confidence';
  }

  // 模擬處理延遲
  await new Promise(resolve => setTimeout(resolve, 500));

  // 返回結果
  return res.status(200).json({
    verified,
    risk_score: riskScore,
    provider: 'mock-kyc-api',
    reason,
    timestamp: new Date().toISOString(),
    user_address,
    document_type
  });
}