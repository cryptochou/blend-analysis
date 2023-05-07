// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC721.sol";
import "./ExchangeStructs.sol";

struct LienPointer {
    Lien lien;
    uint256 lienId;
}

// 交易出价，由借款人创建
struct SellOffer {
    address borrower; // 借款人
    uint256 lienId; // 抵押品id
    uint256 price; // 价格
    uint256 expirationTime; // 过期时间
    uint256 salt;   // 盐
    address oracle; // 预言机
    Fee[] fees;     // 手续费
}

// 留置权
struct Lien {
    address lender; // 出借人
    address borrower; // 借款人
    ERC721 collection; // ERC721合约地址
    uint256 tokenId; // ERC721 token id
    uint256 amount;     // ETH 计价的贷款金额
    uint256 startTime; // 开始时间
    uint256 rate; // 利率
    uint256 auctionStartBlock; // 拍卖开始区块
    uint256 auctionDuration; // 拍卖持续时间
}

// 贷款出价，由拥有资金的出借人创建
struct LoanOffer {
    address lender; // 出借人
    ERC721 collection; // ERC721合约地址
    uint256 totalAmount; // 总数
    uint256 minAmount; // 最小数
    uint256 maxAmount; // 最大数
    uint256 auctionDuration; // 拍卖持续时间
    uint256 salt; // 盐
    uint256 expirationTime; // 过期时间
    uint256 rate; // 利率
    address oracle; // 预言机
}

struct LoanInput {
    LoanOffer offer; // 贷款出价
    bytes signature;
}

struct SellInput {
    SellOffer offer; // 交易出价
    bytes signature;
}

struct Execution {
    Input makerOrder;
    bytes extraSignature;
    uint256 blockNumber;
}
