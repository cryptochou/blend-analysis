# blend-analysis

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [blend-analysis](#blend-analysis)
  - [1. 简介](#1-简介)
    - [1.1 白皮书](#11-白皮书)
    - [1.2 特性](#12-特性)
  - [2. 借贷流程](#2-借贷流程)
    - [2.1 出借人发起借贷出价（Loan Offer）](#21-出借人发起借贷出价loan-offer)
    - [2.2 借款人接受借贷出价，借入资金](#22-借款人接受借贷出价借入资金)
    - [2.3 贷款生成，未进入拍卖阶段](#23-贷款生成未进入拍卖阶段)
      - [2.3.1 借款人](#231-借款人)
      - [2.3.2 出借人](#232-出借人)
    - [2.4 贷款进入拍卖阶段](#24-贷款进入拍卖阶段)
      - [2.4.1 借款人](#241-借款人)
      - [2.4.2 出借人](#242-出借人)
      - [2.4.3 新的出借人](#243-新的出借人)
      - [2.4.4 第三方](#244-第三方)
    - [2.5 清算阶段](#25-清算阶段)
  - [3 交易](#3-交易)
    - [3.1 非抵押 NFT 购买](#31-非抵押-nft-购买)
      - [3.1.1 购买并借款](#311-购买并借款)
        - [3.1.1.1 首付购](#3111-首付购)
    - [3.2 被抵押 NFT 购买](#32-被抵押-nft-购买)
      - [3.2.1 购买被抵押的 NFT](#321-购买被抵押的-nft)
      - [3.2.2 购买被抵押的 NFT，然后重新抵押](#322-购买被抵押的-nft然后重新抵押)
      - [3.2.3 借款人接受对被抵押 NFT 的出价](#323-借款人接受对被抵押-nft-的出价)
  - [4. 代码分析](#4-代码分析)
    - [4.1 Structs 和 ExchangeStructs](#41-structs-和-exchangestructs)
      - [4.1.1 Lien 和 LienPointer](#411-lien-和-lienpointer)
      - [4.1.2 LoanOffer 和 LoanInput](#412-loanoffer-和-loaninput)
      - [4.1.3 SellOffer 和 SellInput](#413-selloffer-和-sellinput)
      - [4.1.4 Execution](#414-execution)
    - [4.2 Blend](#42-blend)
      - [4.2.1 成员变量](#421-成员变量)
        - [4.2.1.1 `liens`](#4211-liens)
        - [4.2.1.2 `amountTaken`](#4212-amounttaken)
        - [4.2.1.3 基本配置](#4213-基本配置)
        - [4.2.1.4 Blur Exchange 配置](#4214-blur-exchange-配置)
        - [4.2.1.5 CALCULATION HELPERS](#4215-calculation-helpers)
      - [4.2.2 方法](#422-方法)
        - [4.2.2.1 BORROW FLOWS](#4221-borrow-flows)
          - [4.2.2.1.1 borrow](#42211-borrow)
          - [4.2.2.1.2 repay](#42212-repay)
        - [4.2.2.2 REFINANCING FLOWS](#4222-refinancing-flows)
          - [4.2.2.2.1 startAuction](#42221-startauction)
          - [4.2.2.2.2 seize](#42222-seize)
          - [4.2.2.2.3 refinance](#42223-refinance)
          - [4.2.2.2.4 refinanceAuction](#42224-refinanceauction)
          - [4.2.2.2.5 refinanceAuctionByOther](#42225-refinanceauctionbyother)
          - [4.2.2.2.6 borrowerRefinance](#42226-borrowerrefinance)
        - [4.2.2.3 MARKETPLACE FLOWS](#4223-marketplace-flows)
          - [4.2.2.3.1 buyToBorrow](#42231-buytoborrow)
          - [4.2.2.3.2 buyToBorrowLocked](#42232-buytoborrowlocked)
          - [4.2.2.3.3 buyLocked](#42233-buylocked)
          - [4.2.2.3.4 takeBid](#42234-takebid)
        - [4.2.2.4 VALIDATION MODIFIERS](#4224-validation-modifiers)
          - [4.2.2.4.1 validateLien](#42241-validatelien)
          - [4.2.2.4.1 lienIsActive](#42241-lienisactive)
          - [4.2.2.4.1 auctionIsActive](#42241-auctionisactive)
    - [4.3 OfferController](#43-offercontroller)
      - [4.3.1 成员变量](#431-成员变量)
      - [4.3.2 方法](#432-方法)
        - [4.3.2.0 \_validateOffer](#4320-_validateoffer)
        - [4.3.2.1 cancelOffer](#4321-canceloffer)
        - [4.3.2.2 incrementNonce](#4322-incrementnonce)
    - [4.4 Signatures](#44-signatures)
    - [4.5 CalculationHelpers](#45-calculationhelpers)
  - [5 总结](#5-总结)
  - [参考](#参考)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 1. 简介

几天前 Blur 推出了 Blend：NFT 的点对点永久借贷协议（the Peer-to-Peer Perpetual Lending Protocol for NFTs）。该协议是 Blur 与 [@Paradigm](https://twitter.com/paradigm) 的 [@danrobinson](https://twitter.com/danrobinson) 和 [@transmissions11](https://twitter.com/transmissions11) 合作的产物。 danrobinson 是 Uniswap V3 的发明者之一。transmissions11 则是 Paradigm 的研究员，也是 Seaport 的主要贡献者。

### 1.1 白皮书

这个链接是白皮书的地址。
https://www.paradigm.xyz/2023/05/blend

### 1.2 特性

Blend 有以下几个特点：

1. Peer-To-Peer（点对点）：Blend 采用点对点的模式，每笔贷款都是单独匹配的。
2. No Oracles（无需预言机）：利率和贷款价值比率由贷款人决定，让市场来调节。
3. Liquidatable（可清算性）：只要贷款人触发了再融资拍卖，如果没有人愿意以任何利率接手债务，NFT就可能被清算。
4. No Expiries（无到期日）：生成的借贷没有到期时间，只要有贷款人愿意用抵押品贷款，贷款就一直有效。只有在利率变化或其中一方想退出头寸时，才需要进行链上交易。

光指出这些特性可能比较不好理解，我们可以简单对比一下 Blend 与另一个 NFT 借贷协议 BendDao 的区别。

1. BendDao 使用点对池的模式，将贷款人的资金汇集成池子。贷款的资金来源是这个池子，同时根据 NFT 种类提供不同额度贷款。Blend 上是点对点的模式，即借款人的资金来自于出借人。
2. BendDao 利用预言机来获取 NFT 的地板价信息。这个信息被用来当做 NFT 定价的基准。比如借贷（borrow）最大能借的金额等数据都是由此决定的。利率方面，BendDao 由借贷池动态决定而在。对应的，Blend 上 NFT 的价格和利率都由出借人决定，交由市场调节。
3. BendDao 上面的借贷有个健康度的指标，当价格波动的时候，健康度会随之变化，如果健康度过低，而且一定的时间内没有补充资金，就会触发清算。 Blend 上的清算则由出借方触发。贷款生成之后，出借方可以随时发起拍卖，如果一定时间内没有匹配新的出借方或者借款人没有全额还款就会触发清算。

BendDao 更多的细节可以参考我之前的一篇文章：https://github.com/cryptochou/BendDAO-analysis

## 2. 借贷流程

在详细分析代码之前，我们需要先了解一下整个借贷流程，以及每个阶段具体角色可以进行的操作。这对后面了解代码有很大的帮助。

我对整体的借贷的流程划分了如下几个阶段。

### 2.1 出借人发起借贷出价（Loan Offer）

出借人在通过借贷获得利息的同时还可以获得借贷积分，借贷积分与 Bid 积分一样，可以提高空投的权重。

出借人发起借贷的时候要选择最大借款额度和想要的利率（APY）。

最大借款额度越高，APY越低，出借人赚取的点数就越多。

这一操作属于链下操作，Loan Offer 存储在中心化服务器上。

### 2.2 借款人接受借贷出价，借入资金

借款人根据自身需求选择接受对应的借贷出价。

这一操作需要与合约进行交互，调用 Blend 合约的 [borrow](#42211-borrow) 方法。

借款人的 NFT 将要被锁定到 Blend 合约中。

### 2.3 贷款生成，未进入拍卖阶段

这个时候根据角色的不同，可进行的操作也不同。

这些操作都需要与合约进行交互。

#### 2.3.1 借款人

1> [repay](#42212-repay)

直接还清贷款。

在清算之前都可以进行还款。

#### 2.3.2 出借人

1> [startAuction](#42221-startauction)

开始拍卖抵押物所有权。调用之后进入拍卖流程。

如果出借人一直不调用这个方法，则贷款会一直存在。直到借款人主动偿还贷款。

2> [refinance](#42223-refinance)

重新融资。接受新的 Loan Offer，用新的出借人的资金来偿还旧的出借人的贷款和利息。

要求新贷款的利率要大于旧贷款，且二者的拍卖时长必须相同。

### 2.4 贷款进入拍卖阶段

#### 2.4.1 借款人

除了上面的 repay 之外，借款人可以调用 [borrowerRefinance](#42226-borrowerrefinance) 来重新融资。也就是接受新的 Loan Offer，用新的出借人的资金来偿还旧的出借人的贷款和利息。

#### 2.4.2 出借人

拍卖过程中出借人也可以进行 [refinance](#42223-refinance)。

#### 2.4.3 新的出借人

[refinanceAuction](#42224-refinanceauction)

拍卖过程中，新的出借人接受清算中的贷款。用新的出借人的资金偿还旧的借款人的贷款和利息。

新的贷款利率根据之前利率和拍卖时间计算，新的贷款金额为之前贷款的利息和本金之和。

#### 2.4.4 第三方

[refinanceAuctionByOther](#42225-refinanceauctionbyother)

当前有一个新的出借人发出的 Loan Offer，可以由第三方撮合该出价。新的出借人接受清算中的贷款。用新的出借人的资金偿还之前借款人的贷款。

与 refinanceAuction 的逻辑基本相同，只是调用者不同。

### 2.5 清算阶段

如果在拍卖结束之后，贷款依然存在，出借人就可以调用 [seize](#42222-seize) 来对违约的贷款进行清算。出借人收到抵押品。

## 3 交易

Blend 中除了借贷，还提供了几个交易的方法。

根据要购买的 NFT 是否被抵押，这些方法可以分为两类。

### 3.1 非抵押 NFT 购买

#### 3.1.1 购买并借款

方法有 [buyToBorrow](#42231-buytoborrow) 和 buyToBorrowETH。

二者的区别是带 ETH 的方法可以使用 ETH 作为资产，方法里面会将 ETH 存入 BlurPool。

使用场景是：当前有一个出借人提出的 Loan Offer，买家从交易所中购买 NFT 并与之撮合，生成新的借款，买家成为借款人。

##### 3.1.1.1 首付购

购买过程中如果贷款金额小于订单金额，则需要买家补足订单金额。

相反则买家只需要支付二者的差额就能完成购买，这种情况就是首付购。可以以较少的资金占有率获得 NFT 的所有权。也是 Blur 官方推荐的用法。

对应了 BendDao 上的 Down Payment 功能。

### 3.2 被抵押 NFT 购买

借款人在抵押了自己的 NFT 后，可以将这个 NFT 的所有权转让。买家购买的时候也将获得对应的债务。

要转让被抵押的 NFT，需要 NFT 的所有者在链下签名一个交易出价（SellOffer）。这样买家才能进行购买。如果 NFT 所有者没有生成交易出价则无法进行购买。

#### 3.2.1 购买被抵押的 NFT

方法包括 [buyLocked](#42233-buylocked) 和 buyLockedETH。

购买被抵押的 NFT，替借款人还清贷款。

使用场景是：当前有一个 Sell Offer，买家接受 Sell Offer，然后替借款人还清贷款。这样买家就获得的 NFT 的所有权。

#### 3.2.2 购买被抵押的 NFT，然后重新抵押

方法包括 [buyToBorrowLocked](#42232-buytoborrowlocked) 和 buyToBorrowLockedETH

购买被抵押的 NFT，还清贷款，然后与指定的贷款出价撮合，生成新的借款。

使用场景是：当前有一个 Sell Offer，和一个 Loan Offer。买家接受 Sell Offer，购买 NFT，替之前的借款人还清贷款，接着与 Loan Offer 撮合，生成新的借款，买家成为借款人获得资金。

#### 3.2.3 借款人接受对被抵押 NFT 的出价

[takeBid](#42234-takebid)

借款人自己可以随时接受对呗抵押 NFT 的出价，并使用资金偿还贷款。

使用场景：当前有一个对借款人的被质押 NFT 的出价。借款人接受这个出价，卖出 NFT，然后使用资金偿还贷款。

## 4. 代码分析

合约地址：https://etherscan.io/address/0x29469395eAf6f95920E59F858042f0e28D98a20B

代码整体结构图如下：

![](classDiagram.svg)

通过上面的图我们可以观察到，主合约是 Blend 合约，主要的逻辑都在这里。此外还有 

1. Structs 和 ExchangeStructs：定义相关数据结构。
2. OfferController：订单的相关逻辑处理。
3. Signatures：签名相关逻辑处理。
4. CalculationHelpers： 利息计算的相关逻辑处理。

由于分析主合约之前，首先要把数据结构先弄清楚。

我们下面按照先分析数据结构，然后是 Blend 合约，接着其他合约的顺序来分析。

### 4.1 Structs 和 ExchangeStructs

Structs 是 Blend 中相关的数据结构。

ExchangeStructs 是 Blur 市场合约中相关的数据结构。具体解析可以查看我的另外一个分析 Blur 的文章。https://github.com/cryptochou/blur-analysis

#### 4.1.1 Lien 和 LienPointer

Lien（留置权）是 Blend 用来存储借贷信息的数据结构。

存储在 Blend 合约中。

```solidity
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

struct LienPointer {
    Lien lien;
    uint256 lienId;
}
```

#### 4.1.2 LoanOffer 和 LoanInput

贷款出价，由拥有资金的出借人创建。表示提供资金的请求。

出借人创建 LoanOffer 后，其被存储在 Blur 中心化服务器中。当借款人借款的时候会选择这个 LoanOffer（贷款出价），然后与 Blend 合约交互生成 Lien（贷款）。

```solidity
struct LoanOffer {
    address lender; // 出借人
    ERC721 collection; // ERC721合约地址
    uint256 totalAmount; // 总数
    uint256 minAmount; // 最小数
    uint256 maxAmount; // 最大数
    uint256 auctionDuration; // 拍卖持续时间
    uint256 salt; // 唯一值，用于 offer 的取消
    uint256 expirationTime; // 过期时间，
    uint256 rate; // 利率
    address oracle; // 预言机（目前没有用到）
}

struct LoanInput {
    LoanOffer offer; // 贷款出价
    bytes signature; // 签名
}
```

#### 4.1.3 SellOffer 和 SellInput

交易出价，由借款人创建。用于出售抵押品 NFT。

借款人创建的 SellOffer 也是存储在 Blur 中心化服务器上。当买家购买该抵押品 NFT 的时候，需要由买家与 Blend 合约交互，生成对应的交易，并还清贷款。

```solidity
struct SellOffer {
    address borrower; // 借款人
    uint256 lienId; // 抵押品id
    uint256 price; // 价格
    uint256 expirationTime; // 过期时间
    uint256 salt;   // 盐，唯一值，用于 offer 的取消。
    address oracle; // 预言机
    Fee[] fees;     // 手续费
}

struct SellInput {
    SellOffer offer; // 交易出价
    bytes signature;
}
```

#### 4.1.4 Execution

用于 Blend 合约调用 Blur Exchange 合约的时候传递订单参数用的数据结构。

```solidity
struct Execution {
    Input makerOrder; // blur 市场合约中的订单数据
    bytes extraSignature;
    uint256 blockNumber;
}
```

### 4.2 Blend

Blend 是一个可升级合约。因此这里的分析的是它的当前实现合约的代码。后续升级的实现合约可能会有一些区别。这点需要注意一下。当然主要功能应该都是大差不差的。

#### 4.2.1 成员变量

这里只分析 Blend 合约中定义的成员变量，父合约中的后面单独分析。

##### 4.2.1.1 `liens`

用来存储 lien（留置权）的信息。

key 是 Lien id。

value 是对 Lien 这一数据计算出来的 hash 值。

```solidity
mapping(uint256 => bytes32) public liens; // lien id => lien 哈希
```

##### 4.2.1.2 `amountTaken`

用于存储一个 LoanOffer 已经接受的贷款金额。

```solidity
mapping(bytes32 => uint256) public amountTaken; // LoanOffer 哈希 => 已接受金额
```

对于一个 LoanOffer 来说可以分多次进行匹配。只要满足其要求就可以。

举个例子来说：

1. 出借人创建一个 LoanOffer（借贷出价），提供了 10 ETH 的资金。
2. 借款人 A 接受该 LoanOffer，借了 6 ETH。生成了一个借贷。这个时候 `amountTaken` 中存的就是 6 ETH。
3. 借款人 B 可以继续接受该 LoanOffer，借了 4 ETH。生成了另外一个借贷。这时候 `amountTaken` 中存的就是 10 ETH。
4. 后面的借款人不能再接受这一 LoanOffer 了。

##### 4.2.1.3 基本配置

1. `_BASIS_POINTS`: 手续费点数
2. `_MAX_AUCTION_DURATION`: 最大拍卖持续时间，当前是 5 天
3. `pool`: Blur ETH Pool，所有的资金都是存储在 Blur Pool 中的。资金的转移也是通过 Blur Pool 进行的。 更多关于 Blur Pool 的信息可以查看[这里](https://github.com/cryptochou/blur-analysis#4-blurpool)
4. `_nextLienId`: 用于记录 lienid 的索引。

##### 4.2.1.4 Blur Exchange 配置

这些配置都是 Blur Exchange 中的相关合约地址。用于从 Blur Exchange 上购买 NFT 的时候进行外部调用。

1. `_EXCHANGE`
2. `_SELL_MATCHING_POLICY`
3. `_BID_MATCHING_POLICY`
4. `_DELEGATE`

##### 4.2.1.5 CALCULATION HELPERS

这两个成员变量的名称与 CalculationHelpers 中的变量名称相同，但是 Blend 当前合约中定义的这两个还没有用到。

1. `_YEAR_WAD`
2. `_LIQUIDATION_THRESHOLD`

#### 4.2.2 方法

##### 4.2.2.1 BORROW FLOWS

借款流程相关的方法。

###### 4.2.2.1.1 borrow

验证并接受 LoanOffer。随后转移资金给借款人并抵押资产。

```solidity
    function borrow(
        LoanOffer calldata offer, // 贷款提议
        bytes calldata signature, // 签名
        uint256 loanAmount, // 借款数量
        uint256 collateralTokenId // 用作抵押品的 NFT 的 tokend id，合约在 LoanOffer 已经被限制。
    ) external returns (uint256 lienId) {
        // 验证并接受 LoanOffer；创建新的 lien。
        lienId = _borrow(offer, signature, loanAmount, collateralTokenId);

        /* Lock collateral token. */ // 抵押 NFT
        offer.collection.safeTransferFrom(msg.sender, address(this), collateralTokenId);

        /* Transfer loan to borrower. */ // 将贷款资金转移到借款人
        pool.transferFrom(offer.lender, msg.sender, loanAmount);
    }

    function _borrow(
        LoanOffer calldata offer,
        bytes calldata signature,
        uint256 loanAmount,
        uint256 collateralTokenId
    ) internal returns (uint256 lienId) {
        // 贷款订单的拍卖时间必须小于最大拍卖时间
        if (offer.auctionDuration > _MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }
        
        // 创建lien数据
        Lien memory lien = Lien({
            lender: offer.lender,
            borrower: msg.sender,
            collection: offer.collection,
            tokenId: collateralTokenId,
            amount: loanAmount,
            startTime: block.timestamp,
            rate: offer.rate,
            auctionStartBlock: 0,
            auctionDuration: offer.auctionDuration
        });

        /* Create lien. */ // 存储 lienid => lien哈希
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        /* Take the loan offer. */ // 验证并接受贷款提议
        _takeLoanOffer(offer, signature, lien, lienId);
    }

    function _takeLoanOffer(
        LoanOffer calldata offer,
        bytes calldata signature,
        Lien memory lien,
        uint256 lienId
    ) internal {
        bytes32 hash = _hashOffer(offer);

        // 校验签名、过期时间、是否已经取消
        _validateOffer(
            hash,
            offer.lender,
            offer.oracle,
            signature,
            offer.expirationTime,
            offer.salt
        );

        // 贷款利率必须小于清算阈值
        if (offer.rate > _LIQUIDATION_THRESHOLD) {
            revert RateTooHigh();
        }
        // 贷款金额必须在最大最小范围内
        if (lien.amount > offer.maxAmount || lien.amount < offer.minAmount) {
            revert InvalidLoan();
        }
        // 获取 LoanOffer 已经接受的贷款金额
        uint256 _amountTaken = amountTaken[hash];
        // 再贷款金额必须小于总贷款金额
        if (offer.totalAmount - _amountTaken < lien.amount) {
            revert InsufficientOffer();
        }
        
        // 更新 LoanOffer 已经接受的贷款金额
        unchecked {
            amountTaken[hash] = _amountTaken + lien.amount;
        }

        // 发送贷款提议接受事件
        emit LoanOfferTaken(
            hash,
            lienId,
            address(offer.collection),
            lien.lender,
            lien.borrower,
            lien.amount,
            lien.rate,
            lien.tokenId,
            lien.auctionDuration
        );
    }
```

###### 4.2.2.1.2 repay

偿还贷款并取回抵押品。

```solidity
    function repay(
        Lien calldata lien, // 借贷的信息
        uint256 lienId
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        // 计算当前的债务偿还并删除 lien 数据
        uint256 debt = _repay(lien, lienId);

        /* Return NFT to borrower. */ // 将 NFT 返回给借款人
        lien.collection.safeTransferFrom(address(this), lien.borrower, lien.tokenId);

        /* Repay loan to lender. */ // 将贷款偿还给贷款人
        pool.transferFrom(msg.sender, lien.lender, debt);
    }

    function _repay(Lien calldata lien, uint256 lienId) internal returns (uint256 debt) {
        // 计算当前的债务
        debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        // 删除 lien 数据
        delete liens[lienId];

        // 发出偿还事件
        emit Repay(lienId, address(lien.collection));
    }
```

##### 4.2.2.2 REFINANCING FLOWS

再融资相关方法。

###### 4.2.2.2.1 startAuction

开启拍卖。

```solidity
    function startAuction(Lien calldata lien, uint256 lienId) external validateLien(lien, lienId) {
        // 调用者必须是出借人
        if (msg.sender != lien.lender) {
            revert Unauthorized();
        }

        /* Cannot start if auction has already started. */ 
        // 如果拍卖已经开始，则无法开始
        if (lien.auctionStartBlock != 0) {
            revert AuctionIsActive();
        }

        /* Add auction start block to lien. */
        // 添加拍卖开始区块时间到 lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    amount: lien.amount,
                    startTime: lien.startTime,
                    rate: lien.rate,
                    auctionStartBlock: block.number,
                    auctionDuration: lien.auctionDuration
                })
            )
        );
        // 发出开始拍卖事件
        emit StartAuction(lienId, address(lien.collection));
    }
```

###### 4.2.2.2.2 seize

从违约的 lien 中没收抵押品，跳过未违约的 lien。

拍卖已经被出借人触发，并且拍卖结束后还没还款的贷款被认定是违约的贷款。

```solidity
    function seize(LienPointer[] calldata lienPointers) external {
        uint256 length = lienPointers.length;
        for (uint256 i; i < length; ) {
            Lien calldata lien = lienPointers[i].lien;
            uint256 lienId = lienPointers[i].lienId;

            // 调用者必须是出借人
            if (msg.sender != lien.lender) {
                revert Unauthorized();
            }
            // 验证lien
            if (!_validateLien(lien, lienId)) {
                revert InvalidLien();
            }

            /* Check that the auction has ended and lien is defaulted. */
            // 检查拍卖是否已经结束并且lien已经违约
            if (_lienIsDefaulted(lien)) {
                // 删除lien数据
                delete liens[lienId];

                /* Seize collateral to lender. */
                // 收回抵押品到出借人
                lien.collection.safeTransferFrom(address(this), lien.lender, lien.tokenId);
                // 发出没收事件
                emit Seize(lienId, address(lien.collection));
            }

            unchecked {
                ++i;
            }
        }
    }
```

###### 4.2.2.2.3 refinance

重新融资。接受新的 Loan Offer，用新的出借人的资金来偿还旧的出借人的贷款和利息。

要求新贷款的利率要大于旧贷款，且二者的拍卖时长必须相同。

```solidity
    function refinance(
        Lien calldata lien, // 旧贷款的信息
        uint256 lienId,
        LoanOffer calldata offer, // 新的贷款提议
        bytes calldata signature
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        // 调用者必须是出借人
        if (msg.sender != lien.lender) {
            revert Unauthorized();
        }

        /* Interest rate must be at least as good as current. */ 
        // 利率必须至少与当前利率一样好 
        // 新利率大于之前的利率并且拍卖持续时间必须一样
        if (offer.rate > lien.rate || offer.auctionDuration != lien.auctionDuration) {
            revert InvalidRefinance();
        }

        // 计算当前贷款金额
        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        _refinance(lien, lienId, debt, offer, signature);

        /* Repay initial loan. */ // 偿还初始贷款
        pool.transferFrom(offer.lender, lien.lender, debt);
    }

    // 重新贷款
    function _refinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        bytes calldata signature
    ) internal {
        if (lien.collection != offer.collection) {
            revert CollectionsDoNotMatch();
        }

        /* Update lien with new loan details. */ // 使用新的贷款详情更新 lien
        Lien memory newLien = Lien({
            lender: offer.lender, // set new lender // 设置新的贷款人
            borrower: lien.borrower,
            collection: lien.collection,
            tokenId: lien.tokenId,
            amount: loanAmount,
            startTime: block.timestamp,
            rate: offer.rate,
            auctionStartBlock: 0, // close the auction // 关闭拍卖
            auctionDuration: offer.auctionDuration
        });
        // 更新 lien
        liens[lienId] = keccak256(abi.encode(newLien));

        /* Take the loan offer. */ // 接受贷款
        _takeLoanOffer(offer, signature, newLien, lienId);
        
        // 发送重新贷款事件
        emit Refinance(
            lienId,
            address(offer.collection),
            offer.lender,
            loanAmount,
            offer.rate,
            offer.auctionDuration
        );
    }
```

###### 4.2.2.2.4 refinanceAuction

拍卖过程中，新的出借人接受清算中的贷款。用新的出借人的资金偿还旧的借款人的贷款和利息。

```solidity
    function refinanceAuction(
        Lien calldata lien,
        uint256 lienId,
        uint256 rate
    ) external validateLien(lien, lienId) auctionIsActive(lien) {
        /* Rate must be below current rate limit. */
        // 利率必须低于当前利率限制
        uint256 rateLimit = CalculationHelpers.calcRefinancingAuctionRate(
            lien.auctionStartBlock,
            lien.auctionDuration,
            lien.rate
        );
        if (rate > rateLimit) {
            revert RateTooHigh();
        }
        // 计算当前贷款金额
        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        /* Reset the lien with the new lender and interest rate. */ // 用新的出借人和利率重置lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: msg.sender, // set new lender
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    amount: debt, // new loan begins with previous debt
                    startTime: block.timestamp,
                    rate: rate,
                    auctionStartBlock: 0, // close the auction
                    auctionDuration: lien.auctionDuration
                })
            )
        );
        // 发出重新融资事件
        emit Refinance(
            lienId,
            address(lien.collection),
            msg.sender,
            debt,
            rate,
            lien.auctionDuration
        );

        /* Repay the initial loan. */ // 偿还初始贷款
        pool.transferFrom(msg.sender, lien.lender, debt);
    }
```

###### 4.2.2.2.5 refinanceAuctionByOther

当前有一个新的出借人发出的 Loan Offer，可以由第三方撮合该出价。新的出借人接受清算中的贷款。用新的出借人的资金偿还之前借款人的贷款。

与 refinanceAuction 的逻辑基本相同，只是调用者不同。

```solidity
    function refinanceAuctionByOther(
        Lien calldata lien,
        uint256 lienId,
        LoanOffer calldata offer,
        bytes calldata signature
    ) external validateLien(lien, lienId) auctionIsActive(lien) {
        
        uint256 rateLimit = CalculationHelpers.calcRefinancingAuctionRate(
            lien.auctionStartBlock,
            lien.auctionDuration,
            lien.rate
        );
        /* Rate must be below current rate limit and auction duration must be the same. */
        // 利率必须低于当前利率限制，拍卖持续时间必须相同
        if (offer.rate > rateLimit || offer.auctionDuration != lien.auctionDuration) {
            revert InvalidRefinance();
        }
        // 计算当前贷款金额
        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        // 重新贷款
        _refinance(lien, lienId, debt, offer, signature);

        /* Repay initial loan. */ // 偿还初始贷款
        pool.transferFrom(offer.lender, lien.lender, debt);
    }
```

###### 4.2.2.2.6 borrowerRefinance

借款人重新融资。也就是接受新的 Loan Offer，用新的出借人的资金来偿还旧的出借人的贷款和利息。

```solidity
    function borrowerRefinance(
        Lien calldata lien,
        uint256 lienId,
        uint256 loanAmount,
        LoanOffer calldata offer,
        bytes calldata signature
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        // 必须由借款人调用
        if (msg.sender != lien.borrower) {
            revert Unauthorized();
        }
        // 必须在最大拍卖持续时间内
        if (offer.auctionDuration > _MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }

        // 重新贷款
        _refinance(lien, lienId, loanAmount, offer, signature);
        // 计算当前贷款金额
        uint256 debt = CalculationHelpers.computeCurrentDebt(lien.amount, lien.rate, lien.startTime);

        if (loanAmount >= debt) {
            /* If new loan is more than the previous, repay the initial loan and send the remaining to the borrower. */ // 如果新贷款超过以前的贷款，则偿还初始贷款并将剩余的发送给借款人
            pool.transferFrom(offer.lender, lien.lender, debt);
            unchecked {
                pool.transferFrom(offer.lender, lien.borrower, loanAmount - debt);
            }
        } else {
            /* If new loan is less than the previous, borrower must supply the difference to repay the initial loan. */ // 如果新贷款小于以前的贷款，则借款人必须提供差额以偿还初始贷款
            pool.transferFrom(offer.lender, lien.lender, loanAmount);
            unchecked {
                pool.transferFrom(lien.borrower, lien.lender, debt - loanAmount);
            }
        }
    }
```

##### 4.2.2.3 MARKETPLACE FLOWS

交易相关方法。

###### 4.2.2.3.1 buyToBorrow

当前有一个出借人提出的 Loan Offer，买家从交易所中购买 NFT 并与之撮合，生成新的借款，买家成为借款人。

```solidity
    function buyToBorrow(
        LoanOffer calldata offer,
        bytes calldata signature,
        uint256 loanAmount,
        Execution calldata execution
    ) public returns (uint256 lienId) {
        // 交易订单的不能是 Blend 创建的订单
        if (execution.makerOrder.order.trader == address(this)) {
            revert Unauthorized();
        }
        // 借款订单的拍卖时间不能超过最大拍卖时间
        if (offer.auctionDuration > _MAX_AUCTION_DURATION) {
            revert InvalidAuctionDuration();
        }

        uint256 collateralTokenId = execution.makerOrder.order.tokenId;
        uint256 price = execution.makerOrder.order.price;

        /* Create lien. */ // 创建lien
        Lien memory lien = Lien({
            lender: offer.lender,
            borrower: msg.sender,
            collection: offer.collection,
            tokenId: collateralTokenId,
            amount: loanAmount,
            startTime: block.timestamp,
            rate: offer.rate,
            auctionStartBlock: 0,
            auctionDuration: offer.auctionDuration
        });
        unchecked {
            // 存储lienid
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        /* Take the loan offer. */ // 验证并接受贷款提议
        _takeLoanOffer(offer, signature, lien, lienId);

        /* Transfer funds. */ // 转移资金
        /* Need to retrieve the ETH to funds the marketplace execution. */ 
        // 需要转移 ETH 来保证市场合约执行订单的成交
        if (loanAmount < price) { // 如果贷款金额小于订单价格
            /* Take funds from lender. */ // 从贷款人那里拿走资金
            pool.withdrawFrom(offer.lender, address(this), loanAmount);

            /* Supplement difference from borrower. */ // 从借款人那里补充差额
            unchecked {
                pool.withdrawFrom(msg.sender, address(this), price - loanAmount);
            }
        } else { // 如果贷款金额大于订单价格
            /* Take funds from lender. */ // 从贷款人那里拿走资金
            pool.withdrawFrom(offer.lender, address(this), price);

            /* Send surplus to borrower. */ // 将剩余资金发送给借款人
            unchecked {
                pool.transferFrom(offer.lender, msg.sender, loanAmount - price);
            }
        }

        /* Create the buy side order coming from Blend. */ // 创建买单
        Order memory buyOrder = Order({
            trader: address(this), // 订单的创建者是当前合约
            side: Side.Buy,
            matchingPolicy: _SELL_MATCHING_POLICY,
            collection: address(offer.collection),
            tokenId: collateralTokenId,
            amount: 1,
            paymentToken: address(0),
            price: price,
            listingTime: execution.makerOrder.order.listingTime + 1, // listingTime determines maker/taker 在 blur市场合约中 maker/taker 是由 listingTime 来决定的，买单时间大，表明此次是由买家触发，事件中的 maker 是买家。相反的 maker 是卖家表明是有卖家触发的订单。
            expirationTime: type(uint256).max,
            fees: new Fee[](0),
            salt: uint160(execution.makerOrder.order.trader), // prevent reused order hash  防止重复使用订单哈希
            extraParams: "\x01" // require oracle signature 需要预言机签名
        });
        Input memory buy = Input({
            order: buyOrder,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            extraSignature: execution.extraSignature,
            signatureVersion: SignatureVersion.Single,
            blockNumber: execution.blockNumber
        });

        /* Execute order using ETH currently in contract. */ // 使用当前合约中的 ETH 执行订单
        _EXCHANGE.execute{ value: price }(execution.makerOrder, buy);
    }
```

###### 4.2.2.3.2 buyToBorrowLocked

购买被抵押的 NFT，还清贷款，然后与指定的贷款出价撮合，生成新的借款。

```solidity
    function buyToBorrowLocked(
        Lien calldata lien,
        SellInput calldata sellInput,
        LoanInput calldata loanInput,
        uint256 loanAmount
    )
        public
        validateLien(lien, sellInput.offer.lienId)
        lienIsActive(lien)
        returns (uint256 lienId)
    {   
        // 购买和抵押订单的 NFT 合约必须相同
        if (lien.collection != loanInput.offer.collection) {
            revert CollectionsDoNotMatch();
        }
        // 购买被锁定的抵押品，并用从销售中获得的资金偿还贷款
        // priceAfterFees 是从销售中获得的资金
        // debt 是需要偿还的贷款
        (uint256 priceAfterFees, uint256 debt) = _buyLocked(
            lien,
            sellInput.offer,
            sellInput.signature
        );

        // 验证并接受贷款提议；创建新的lien
        lienId = _borrow(loanInput.offer, loanInput.signature, loanAmount, lien.tokenId);

        /* Transfer funds. */ // 转移资金
        /* Need to repay the original loan and payout any surplus from the sell or loan funds. */ 
        // 需要偿还原始贷款，并从销售或贷款资金中支付任何剩余资金
        if (loanAmount < debt) { // 如果贷款金额小于需要偿还的贷款
            /* loanAmount < debt < priceAfterFees */

            /* Repay loan with funds from new lender to old lender. */ 
            // 用新贷款人的资金偿还旧贷款人的贷款
            pool.transferFrom(loanInput.offer.lender, lien.lender, loanAmount); // doesn't cover debt

            unchecked {
                /* Supplement difference from new borrower. */ // 从新借款人那里补充差额
                pool.transferFrom(msg.sender, lien.lender, debt - loanAmount); // cover rest of debt

                /* Send rest of sell funds to borrower. */ // 将剩余的销售资金发送给借款人
                pool.transferFrom(msg.sender, sellInput.offer.borrower, priceAfterFees - debt);
            }
        } else if (loanAmount < priceAfterFees) {
            /* debt < loanAmount < priceAfterFees */ 
            // 如果贷款金额大于需要偿还的贷款，但小于从销售中获得的资金

            /* Repay loan with funds from new lender to old lender. */ 
            // 用新贷款人的资金偿还旧贷款人的贷款
            pool.transferFrom(loanInput.offer.lender, lien.lender, debt);

            unchecked {
                /* Send rest of loan from new lender to old borrower. */ 
                // 将剩余的贷款从新贷款人发送给旧借款人
                pool.transferFrom(
                    loanInput.offer.lender,
                    sellInput.offer.borrower,
                    loanAmount - debt
                );

                /* Send rest of sell funds from new borrower to old borrower. */ 
                // 将剩余的销售资金从新借款人发送给旧借款人
                pool.transferFrom(
                    msg.sender,
                    sellInput.offer.borrower,
                    priceAfterFees - loanAmount
                );
            }
        } else {
            /* debt < priceAfterFees < loanAmount */ 
            // 如果贷款金额大于从销售中获得的资金

            /* Repay loan with funds from new lender to old lender. */ 
            // 用新贷款人的资金偿还旧贷款人的贷款
            pool.transferFrom(loanInput.offer.lender, lien.lender, debt);

            unchecked {
                /* Send rest of sell funds from new lender to old borrower. */ 
                // 将剩余的销售资金从新贷款人发送给旧借款人
                pool.transferFrom(
                    loanInput.offer.lender,
                    sellInput.offer.borrower,
                    priceAfterFees - debt
                );

                /* Send rest of loan from new lender to new borrower. */ 
                // 将剩余的贷款从新贷款人发送给新借款人
                pool.transferFrom(loanInput.offer.lender, msg.sender, loanAmount - priceAfterFees);
            }
        }
    }

    function _buyLocked(
        Lien calldata lien,
        SellOffer calldata offer,
        bytes calldata signature
    ) internal returns (uint256 priceAfterFees, uint256 debt) {
        // lien的借款人必须是卖单的借款人
        if (lien.borrower != offer.borrower) {
            revert Unauthorized();
        }
        // 验证、履行和转移出售请求上的费用，返回去除手续费的价格
        priceAfterFees = _takeSellOffer(offer, signature);

        /* Repay loan with funds received from the sale. */
        // 用从销售中获得的资金偿还贷款,
        debt = _repay(lien, offer.lienId);
        if (priceAfterFees < debt) {
            revert InvalidRepayment();
        }

        emit BuyLocked(
            offer.lienId,
            address(lien.collection),
            msg.sender,
            lien.borrower,
            lien.tokenId
        );
    }

    function _takeSellOffer(
        SellOffer calldata sellOffer,
        bytes calldata sellSignature
    ) internal returns (uint256 priceAfterFees) {
        // 验证出售请求
        _validateOffer(
            _hashSellOffer(sellOffer),
            sellOffer.borrower,
            sellOffer.oracle,
            sellSignature,
            sellOffer.expirationTime,
            sellOffer.salt
        );

        /* Mark the sell offer as fulfilled. */ // 将出售请求标记为已完成
        cancelledOrFulfilled[sellOffer.borrower][sellOffer.salt] = 1;

        /* Transfer fees. */
        uint256 totalFees = _transferFees(sellOffer.fees, msg.sender, sellOffer.price);
        unchecked {
            priceAfterFees = sellOffer.price - totalFees;
        }
    }
```

###### 4.2.2.3.3 buyLocked

购买被抵押的 NFT，替借款人还清贷款。

```solidity
    function buyLocked(
        Lien calldata lien,
        SellOffer calldata offer,
        bytes calldata signature
    ) public validateLien(lien, offer.lienId) lienIsActive(lien) {
        // 购买被锁定的抵押品，并用从销售中获得的资金偿还贷款
        // priceAfterFees 是从销售中获得的资金
        // debt 是需要偿还的贷款
        (uint256 priceAfterFees, uint256 debt) = _buyLocked(lien, offer, signature);

        /* Send token to buyer. */ // 将代币发送给买家
        lien.collection.safeTransferFrom(address(this), msg.sender, lien.tokenId);

        /* Repay lender. */ // 偿还贷款
        pool.transferFrom(msg.sender, lien.lender, debt);

        /* Send surplus to borrower. */ // 将剩余资金发送给借款人
        unchecked {
            pool.transferFrom(msg.sender, lien.borrower, priceAfterFees - debt);
        }
    }
```

###### 4.2.2.3.4 takeBid

借款人自己可以随时接受对呗抵押 NFT 的出价，并使用资金偿还贷款。

```solidity
function takeBid(
        Lien calldata lien,
        uint256 lienId,
        Execution calldata execution
    ) external validateLien(lien, lienId) lienIsActive(lien) {
        // bid 订单的创建者不能是 blend 合约，且 msg.sender 必须是借款人
        if (execution.makerOrder.order.trader == address(this) || msg.sender != lien.borrower) {
            revert Unauthorized();
        }

        /* Repay loan with funds received from the sale. */ 
        // 用从销售中获得的资金偿还贷款
        uint256 debt = _repay(lien, lienId);

        /* Create sell side order from Blend. */ 
        // 从 Blend 创建卖单
        Order memory sellOrder = Order({
            trader: address(this),
            side: Side.Sell,
            matchingPolicy: _BID_MATCHING_POLICY,
            collection: address(lien.collection),
            tokenId: lien.tokenId,
            amount: 1,
            paymentToken: address(pool),
            price: execution.makerOrder.order.price,
            listingTime: execution.makerOrder.order.listingTime + 1, // listingTime determines maker/taker
            expirationTime: type(uint256).max,
            fees: new Fee[](0),
            salt: lienId, // prevent reused order hash 
            extraParams: "\x01" // require oracle signature
        });
        Input memory sell = Input({
            order: sellOrder,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            extraSignature: execution.extraSignature,
            signatureVersion: SignatureVersion.Single,
            blockNumber: execution.blockNumber
        });

        /* Execute marketplace order. */ // 执行市场订单
        uint256 balanceBefore = pool.balanceOf(address(this));
        lien.collection.approve(_DELEGATE, lien.tokenId);
        _EXCHANGE.execute(sell, execution.makerOrder);

        /* Determine the funds received from the sale (after fees). */ 
        // 确定从销售中获得的资金（扣除手续费后）
        uint256 amountReceivedFromSale = pool.balanceOf(address(this)) - balanceBefore;
        if (amountReceivedFromSale < debt) {
            revert InvalidRepayment();
        }

        /* Repay lender. */ // 偿还贷款
        pool.transferFrom(address(this), lien.lender, debt);

        /* Send surplus to borrower. */ // 将剩余资金发送给借款人
        unchecked {
            pool.transferFrom(address(this), lien.borrower, amountReceivedFromSale - debt);
        }
    }
```

##### 4.2.2.4 VALIDATION MODIFIERS

###### 4.2.2.4.1 validateLien

判断 Lien 是否是有效的。

```solidity
    modifier validateLien(Lien calldata lien, uint256 lienId) {
        if (!_validateLien(lien, lienId)) {
            revert InvalidLien();
        }

        _;
    }

    function _validateLien(Lien calldata lien, uint256 lienId) internal view returns (bool) {
        return liens[lienId] == keccak256(abi.encode(lien));
    }
```

###### 4.2.2.4.1 lienIsActive

判断 Lien 是否是活跃的，也就是是否违约。

拍卖已经被出借人触发，并且拍卖结束后还没还款的贷款被认定是违约的贷款。

```solidity
    modifier lienIsActive(Lien calldata lien) {
        if (_lienIsDefaulted(lien)) {
            revert LienIsDefaulted();
        }

        _;
    }

    // 判断lien是否已经违约
    function _lienIsDefaulted(Lien calldata lien) internal view returns (bool) {
        return
            lien.auctionStartBlock != 0 && // 拍卖已经开始
            lien.auctionStartBlock + lien.auctionDuration < block.number; // 拍卖已经结束
    }
```

###### 4.2.2.4.1 auctionIsActive

判断拍卖是否是正在进行。

```solidity
    modifier auctionIsActive(Lien calldata lien) {
        if (!_auctionIsActive(lien)) {
            revert AuctionIsNotActive();
        }

        _;
    }

    // 判断拍卖是否已经开始
    function _auctionIsActive(Lien calldata lien) internal view returns (bool) {
        return
            lien.auctionStartBlock != 0 && // 拍卖已经开始
            lien.auctionStartBlock + lien.auctionDuration >= block.number; // 拍卖还未结束
    }
```

### 4.3 OfferController

Blend 继承自该合约。该合约主要用来校验出价信息，并记录出价的取消状态。

#### 4.3.1 成员变量

cancelledOrFulfilled 用来记录被取消的出价，防止出价的重放攻击。

外层字典的 key 是 address 类型的用户地址。对于 LoanOffer 来说是 出借人的地址，对 SellOffer 来说是抵押品的拥有者，也就是借款人。

内层字典的 key 是 订单的 salt 信息。可以看成是唯一值。value 如果是 1，则表示对应的 offer 已经被取消。

```solidity
mapping(address => mapping(uint256 => uint256)) public cancelledOrFulfilled;
```

#### 4.3.2 方法

##### 4.3.2.0 _validateOffer

```solidity
    function _validateOffer(
        bytes32 offerHash,
        address signer,
        address oracle,
        bytes calldata signature,
        uint256 expirationTime,
        uint256 salt
    ) internal view {
        // 校验签名
        _verifyOfferAuthorization(offerHash, signer, oracle, signature);

        // 校验过期时间
        if (expirationTime < block.timestamp) {
            revert OfferExpired();
        }
        // 校验是否已经取消
        if (cancelledOrFulfilled[signer][salt] == 1) {
            revert OfferUnavailable();
        }
    }

```

##### 4.3.2.1 cancelOffer

```solidity
    // 取消单个 offer
    function cancelOffer(uint256 salt) external {
        _cancelOffer(msg.sender, salt);
    }

    // 取消多个 offer
    function cancelOffers(uint256[] calldata salts) external {
        uint256 saltsLength = salts.length;
        for (uint256 i; i < saltsLength; ) {
            _cancelOffer(msg.sender, salts[i]);
            unchecked {
                ++i;
            }
        }
    }
    // 设置 offer
    function _cancelOffer(address user, uint256 salt) private {
        cancelledOrFulfilled[user][salt] = 1;
        emit OfferCancelled(user, salt);
    }

```

##### 4.3.2.2 incrementNonce

通过增加用户的 nonce 值，将之前签名的 offer 全部取消。

```solidity
    function incrementNonce() external {
        _incrementNonce(msg.sender);
    }

    function _incrementNonce(address user) internal {
        emit NonceIncremented(user, ++nonces[user]);
    }
```

### 4.4 Signatures

OfferController 合约继承自 Signatures 合约。因此 Blend 也继承自 Signatures，拥有 Signatures 中的一系列方法。

Signatures 合约主要是用来做一些签名校验，hash 计算等工作的。

需要注意的是 oracles 这个成员变量。他不是预言机，而是用于校验 Blur Exchange 中的 Oracle 类型的订单的。更多信息可以看[这里](https://github.com/cryptochou/blur-analysis#2342-oracle-authorization)。

### 4.5 CalculationHelpers

该合约主要用来计算债务和重新融资的利率的。并给出了具体的计算公式。感兴趣的可以去研究一下。这里不再深入了。

```solidity
/**
     * @dev Computes the current debt of a borrow given the last time it was touched and the last computed debt. 计算借款的当前债务，给定上次触及借款的时间和上次计算的债务。
     * @param amount Principal in ETH 
     * @param startTime Start time of the loan
     * @param rate Interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/l6omp0rwnh
     */
    function computeCurrentDebt(
        uint256 amount,
        uint256 rate,
        uint256 startTime
    ) external view returns (uint256) {
        // 计算借款时间
        uint256 loanTime = block.timestamp - startTime;
        // 如果借款时间小于最小借款时间，则借款时间为最小借款时间
        if (loanTime < _MIN_LOAN_TIME) {
            loanTime = _MIN_LOAN_TIME;
        }
        // 计算借款年数
        int256 yearsWad = wadDiv(int256(loanTime) * 1e18, _YEAR_WAD);
        // 计算借款利息
        return uint256(wadMul(int256(amount), wadExp(wadMul(yearsWad, bipsToSignedWads(rate)))));
    }

    /**
     * @dev Calculates the current maximum interest rate a specific refinancing
     * auction could settle at currently given the auction's start block and duration. 计算当前特定的再融资拍卖可以结算的最高利率，给定拍卖的开始区块和持续时间。
     * @param startBlock The block the auction started at
     * @param oldRate Previous interest rate (in bips)
     * @dev Formula: https://www.desmos.com/calculator/urasr71dhb
     */
    function calcRefinancingAuctionRate(
        uint256 startBlock,
        uint256 auctionDuration,
        uint256 oldRate
    ) external view returns (uint256) {
        uint256 currentAuctionBlock = block.number - startBlock;
        int256 oldRateWads = bipsToSignedWads(oldRate);

        uint256 auctionT1 = auctionDuration / 5;
        uint256 auctionT2 = (4 * auctionDuration) / 5;

        int256 maxRateWads;
        {
            int256 aInverse = -bipsToSignedWads(15000);
            int256 b = 2;
            int256 maxMinRateWads = bipsToSignedWads(500);

            if (oldRateWads < -((b * aInverse) / 2)) {
                maxRateWads = maxMinRateWads + (oldRateWads ** 2) / aInverse + b * oldRateWads;
            } else {
                maxRateWads = maxMinRateWads - ((b ** 2) * aInverse) / 4;
            }
        }

        int256 startSlope = maxRateWads / int256(auctionT1); // wad-bips per block

        int256 middleSlope = bipsToSignedWads(9000) / int256(3 * auctionDuration / 5) + 1; // wad-bips per block (add one to account for rounding)
        int256 middleB = maxRateWads - int256(auctionT1) * middleSlope;

        if (currentAuctionBlock < auctionT1) {
            return signedWadsToBips(startSlope * int256(currentAuctionBlock));
        } else if (currentAuctionBlock < auctionT2) {
            return signedWadsToBips(middleSlope * int256(currentAuctionBlock) + middleB);
        } else if (currentAuctionBlock < auctionDuration) {
            int256 endSlope;
            int256 endB;
            {
                endSlope =
                    (bipsToSignedWads(_LIQUIDATION_THRESHOLD) -
                        ((int256(auctionT2) * middleSlope) + middleB)) /
                    int256(auctionDuration - auctionT2); // wad-bips per block
                endB =
                    bipsToSignedWads(_LIQUIDATION_THRESHOLD) -
                    int256(auctionDuration) *
                    endSlope;
            }

            return signedWadsToBips(endSlope * int256(currentAuctionBlock) + endB);
        } else {
            return _LIQUIDATION_THRESHOLD;
        }
    }
```

## 5 总结

通过上面的分析，Blend 合约给我的感觉和 Blur Exchange 很类似。

代码都很简练，而且都聚焦于最核心的功能。没有去做大而全的东西。这个跟 Blur 整个产品给人的感觉是一以贯之的。

回到 Blend 的特性来说，Blend 是点对点的借贷协议，并且舍弃了 Oracle 定价，将定价权和利率的决定权都交给市场，让市场进行调节。相对于 BendDao 那种点对池的借贷协议，Blend 无疑是更加灵活的。

同时 Blend 与 Blur Exchange 市场合约进行了整合。提供了抵押品的交易和 bid。这在一定程度上提升了 NFT 的流动性。二者相结合也许会碰撞出新的火花。

当然目前看来 Blend 可能还存在着一些缺点（额，也不能称之为缺点，应该是当前机制下的特性）。

比如 [@mindaoyang](https://twitter.com/mindaoyang/status/1653666517870067712) 提到的：

>核心问题：这是对贷款人友好，对借款人不友好的协议设计。
>对借款人来说，因为贷款人可任何时候发起“再融资”
>借款人需要为这个贷款人的“选择权”支付更高的代价

以及 [@qiaoyunzi1](https://twitter.com/qiaoyunzi1/status/1654387280398909440) 提到的：

> 经由这个操作，我更新了对Blur的Blend产品的观点，之前我认为BNPL类似于房地产放水，但是银行与房屋买家是有合同签订的，买家不至于太弱势。而BNPL对“银行”也就是贷款人没有约束，贷款人更自由，对于贷款人和卖家来说，他们更有优势，而买家更弱势。

至于未来 Blend 会如何发展，让我们拭目以待了。

## 参考

https://twitter.com/mindaoyang/status/1653666517870067712
https://twitter.com/anymose96/status/1653965719904845824
https://twitter.com/0xJamesXXX/status/1653064449887174659
https://twitter.com/qiaoyunzi1/status/1654387280398909440
https://twitter.com/anymose96/status/1653213709056233475

如果感觉本文对您有帮助的话，欢迎打赏：
0x1E1eFeb696Bc8F3336852D9FB2487FE6590362BF。