// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KYCOracle
 * @notice 不需信任的 KYC 預言機合約 - 使用 Oasis Sapphire ROFL
 */
contract KYCOracle {
    address public roflAppAddress;
    address public owner;
    
    // Oasis Sapphire ROFL 識別
    bytes21 public roflAppID;
    
    struct KYCStatus {
        bool verified;
        uint8 riskLevel;
        uint256 timestamp;
        bytes32 proofHash;
    }
    
    mapping(address => KYCStatus) private kycRecords;
    
    event KYCVerified(address indexed user, bool verified, uint8 riskLevel, uint256 timestamp);
    event ROFLAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ROFLAppIDSet(bytes21 indexed appID);
    
    // Sapphire ROFL 預編譯合約地址
    address constant ROFL_ORIGIN = 0x0100000000000000000000000000000000000103;
    
    modifier onlyROFL() {
        require(msg.sender == roflAppAddress, "Only ROFL app can call");
        
        // 使用 Oasis Sapphire 的 roflEnsureAuthorizedOrigin
        // 確保呼叫來自授權的 ROFL App
        if (roflAppID.length > 0) {
            (bool success, bytes memory data) = ROFL_ORIGIN.call(
                abi.encodeWithSignature("roflEnsureAuthorizedOrigin(bytes21)", roflAppID)
            );
            require(success && abi.decode(data, (bool)), "Unauthorized ROFL origin");
        }
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @notice 設定 ROFL App ID（用於 roflEnsureAuthorizedOrigin 驗證）
     * @param _appID ROFL App 的唯一識別碼
     */
    function setROFLAppID(bytes21 _appID) external onlyOwner {
        roflAppID = _appID;
        emit ROFLAppIDSet(_appID);
    }
    
    /**
     * @notice 設定 ROFL 服務地址
     * @param _roflApp ROFL 服務的錢包地址
     */
    function setROFLAddress(address _roflApp) external onlyOwner {
        require(_roflApp != address(0), "Invalid address");
        address oldAddress = roflAppAddress;
        roflAppAddress = _roflApp;
        emit ROFLAddressUpdated(oldAddress, _roflApp);
    }
    
    /**
     * @notice ROFL 服務更新用戶 KYC 狀態
     * @dev 使用 onlyROFL modifier 確保呼叫來自授權的 ROFL App
     * @param user 用戶錢包地址
     * @param verified 是否通過驗證
     * @param riskLevel 風險等級 (0-100)
     * @param proofHash 驗證證明雜湊
     */
    function updateKYCStatus(
        address user,
        bool verified,
        uint8 riskLevel,
        bytes32 proofHash
    ) external onlyROFL {
        require(user != address(0), "Invalid user address");
        require(riskLevel <= 100, "Risk level must be 0-100");
        
        kycRecords[user] = KYCStatus({
            verified: verified,
            riskLevel: riskLevel,
            timestamp: block.timestamp,
            proofHash: proofHash
        });
        
        emit KYCVerified(user, verified, riskLevel, block.timestamp);
    }
    
    /**
     * @notice 查詢用戶是否通過 KYC
     * @param user 用戶錢包地址
     * @return 是否通過驗證
     */
    function isKYCVerified(address user) external view returns (bool) {
        return kycRecords[user].verified;
    }
    
    /**
     * @notice 查詢用戶完整 KYC 狀態
     * @param user 用戶錢包地址
     * @return verified 是否通過驗證
     * @return riskLevel 風險等級
     * @return timestamp 驗證時間戳
     * @return proofHash 證明雜湊
     */
    function getKYCStatus(address user) external view returns (
        bool verified,
        uint8 riskLevel,
        uint256 timestamp,
        bytes32 proofHash
    ) {
        KYCStatus memory status = kycRecords[user];
        return (
            status.verified,
            status.riskLevel,
            status.timestamp,
            status.proofHash
        );
    }
    
    /**
     * @notice 查詢用戶風險等級
     * @param user 用戶錢包地址
     * @return 風險等級 (0-100)
     */
    function getRiskLevel(address user) external view returns (uint8) {
        return kycRecords[user].riskLevel;
    }
    
    /**
     * @notice 取得當前設定的 ROFL App ID
     * @return ROFL App 識別碼
     */
    function getROFLAppID() external view returns (bytes21) {
        return roflAppID;
    }
}
