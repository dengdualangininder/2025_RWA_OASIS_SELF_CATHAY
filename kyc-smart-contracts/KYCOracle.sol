// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KYCOracle {
    // ROFL 應用的授權地址
    address public roflAppAddress;
    address public owner;
    
    // KYC 狀態記錄
    struct KYCStatus {
        bool verified;
        uint8 riskLevel;  // 0-100，數字越小風險越低
        uint256 timestamp;
        bytes32 proofHash;
    }
    
    mapping(address => KYCStatus) private kycRecords;
    
    // 事件
    event KYCVerified(address indexed user, bool verified, uint8 riskLevel, uint256 timestamp);
    event ROFLAddressUpdated(address indexed oldAddress, address indexed newAddress);
    
    // 修飾符
    modifier onlyROFL() {
        require(msg.sender == roflAppAddress, "Only ROFL app can call");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // 初始時 roflAppAddress 為 0，部署 ROFL 後再設定
    }
    
    // 設定 ROFL 應用地址
    function setROFLAddress(address _roflApp) external onlyOwner {
        require(_roflApp != address(0), "Invalid address");
        address oldAddress = roflAppAddress;
        roflAppAddress = _roflApp;
        emit ROFLAddressUpdated(oldAddress, _roflApp);
    }
    
    // ROFL 應用呼叫此函數更新 KYC 狀態
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
    
    // 公開查詢：是否通過 KYC
    function isKYCVerified(address user) external view returns (bool) {
        return kycRecords[user].verified;
    }
    
    // 公開查詢：完整 KYC 狀態
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
    
    // 查詢風險等級
    function getRiskLevel(address user) external view returns (uint8) {
        return kycRecords[user].riskLevel;
    }
    
    // 批量查詢
    function batchCheckKYC(address[] calldata users) external view returns (bool[] memory) {
        bool[] memory results = new bool[](users.length);
        for (uint i = 0; i < users.length; i++) {
            results[i] = kycRecords[users[i]].verified;
        }
        return results;
    }
}
