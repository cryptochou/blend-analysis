# blend-analysis

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

这一操作需要与合约进行交互，调用 Blend 合约的 borrow 方法。

借款人的 NFT 将要被锁定到 Blend 合约中。

### 2.3 贷款生成，未进入拍卖阶段

这个时候根据角色的不同，可进行的操作也不同。

这些操作都需要与合约进行交互。

#### 2.3.1 借款人

1> repay

直接还清贷款。

在清算之前都可以进行还款。

#### 2.3.2 出借人

1> startAuction

开始拍卖抵押物所有权。调用之后进入拍卖流程。

如果出借人一直不调用这个方法，则贷款会一直存在。直到借款人主动偿还贷款。

2> refinance

重新融资。接受新的 Loan Offer，用新的出借人的资金来偿还旧的出借人的贷款和利息。

要求新贷款的利率要大于旧贷款，且二者的拍卖时长必须相同。

### 2.4 贷款进入拍卖阶段

#### 2.4.1 借款人

除了上面的 repay 之外，借款人可以调用 borrowerRefinance 来重新融资。也就是接受新的 Loan Offer，用新的出借人的资金来偿还旧的出借人的贷款和利息。

#### 2.4.2 出借人

拍卖过程中出借人也可以进行 refinance。

#### 2.4.3 新的出借人

refinanceAuction

拍卖过程中，新的出借人接受清算中的贷款。用新的出借人的资金偿还旧的借款人的贷款和利息。

新的贷款利率根据之前利率和拍卖时间计算，新的贷款金额为之前贷款的利息和本金之和。

#### 2.4.4 第三方

refinanceAuctionByOther

当前有一个新的出借人发出的 Loan Offer，可以由第三方撮合该出价。新的出借人接受清算中的贷款。用新的出借人的资金偿还之前借款人的贷款。

与 refinanceAuction 的逻辑基本相同，只是调用者不同。

### 2.5 清算阶段

如果在拍卖结束之后，贷款依然存在，出借人就可以调用 seize 来对违约的贷款进行清算。出借人收到抵押品。

## 3 交易

Blend 中除了借贷，还提供了几个交易的方法。

根据要购买的 NFT 是否被抵押，这些方法可以分为两类。

### 3.1 非抵押 NFT 购买

#### 3.1.1 购买并借款

方法有 buyToBorrow 和 buyToBorrowETH。

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

方法包括 buyLocked 和 buyLockedETH。

购买被抵押的 NFT，替借款人还清贷款。

使用场景是：当前有一个 Sell Offer，买家接受 Sell Offer，然后替借款人还清贷款。这样买家就获得的 NFT 的所有权。

#### 3.2.2 购买被抵押的 NFT，然后重新抵押

方法包括 buyToBorrowLocked 和 buyToBorrowLockedETH

购买被抵押的 NFT，还清贷款，然后与指定的贷款出价撮合，生成新的借款。

使用场景是：当前有一个 Sell Offer，和一个 Loan Offer。买家接受 Sell Offer，购买 NFT，替之前的借款人还清贷款，接着与 Loan Offer 撮合，生成新的借款，买家成为借款人获得资金。

#### 3.2.3 借款人接受对被抵押 NFT 的出价

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

我们一个个进行分析。

### 4.1 Structs 和 ExchangeStructs

分析主合约之前，首先要把数据结构先弄清楚。

Structs 是 Blend 中相关的数据结构。

ExchangeStructs 是 Blur 市场合约中相关的数据结构。具体解析可以查看我的另外一个分析 Blur 的文章。https://github.com/cryptochou/blur-analysis

#### 4.1.1 Lien 和 LienPointer

```solidity
// 留置权，
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

```solidity
// 贷款出价，由拥有资金的出借人创建
struct LoanOffer {
    address lender; // 出借人
    ERC721 collection; // ERC721合约地址
    uint256 totalAmount; // 总数
    uint256 minAmount; // 最小数
    uint256 maxAmount; // 最大数
    uint256 auctionDuration; // 拍卖持续时间
    uint256 salt; 
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

```solidity
// 交易出价，由借款人创建。用于出售抵押品 NFT。
struct SellOffer {
    address borrower; // 借款人
    uint256 lienId; // 抵押品id
    uint256 price; // 价格
    uint256 expirationTime; // 过期时间
    uint256 salt;   // 盐
    address oracle; // 预言机
    Fee[] fees;     // 手续费
}

struct SellInput {
    SellOffer offer; // 交易出价
    bytes signature;
}
```

#### 4.1.4 Execution

```solidity
struct Execution {
    Input makerOrder; // blur 市场合约中的订单数据
    bytes extraSignature;
    uint256 blockNumber;
}
```

## 参考

https://twitter.com/mindaoyang/status/1653666517870067712
https://twitter.com/anymose96/status/1653965719904845824
https://twitter.com/0xJamesXXX/status/1653064449887174659
https://twitter.com/qiaoyunzi1/status/1654387280398909440
https://twitter.com/anymose96/status/1653213709056233475


借款人

borrow
借款

repay
还款

borrowerRefinance
在拍卖阶段，借款人重新借款，然后偿还之前的借款
使用场景是：当前有一个新的 loanoffer，借款人接受这个 loanoffer，生成新的贷款，然后用新的出借人的资金偿还之前的借款。

takeBid
接受锁定 NFT 的出价，并使用资金偿还贷款
使用场景：当前有一个对质押 NFT 的出价。借款人接受这个出价，卖出 NFT，然后使用资金偿还贷款。

出借人

startAuction
开始拍卖抵押物所有权，设置 lien 中的 auctionStartBlock: block.number,  auctionDuration: lien.auctionDuration

seize
没收违约的抵押品。判定违约的条件是：借款人没有在拍卖结束之前的时间内偿还贷款。

refinance
重新融资，接受新的 loanoffer，用新贷款的出借人的资金偿还之前借款人的贷款。

新的出借人

refinanceAuction
拍卖中重新融资，偿还之前的贷款，根据当前债务生成新的借贷。新的贷款利率根据之前利率和拍卖时间计算，新的贷款金额为之前贷款的利息和本金之和。
使用场景：新的出借人接受清算中的贷款。用新的出借人的资金偿还之前借款人的贷款。

第三方

refinanceAuctionByOther
拍卖中重新融资，偿还之前的贷款，根据新的金额生成新的借贷。新的贷款利率根据之前利率和拍卖时间计算，新的贷款金额为新的金额。
使用场景：当前有一个新的出借人发出的 loanoffer，可以由第三方撮合该出价。新的出借人接受清算中的贷款。用新的出借人的资金偿还之前借款人的贷款。

买家

buyToBorrow 0x8593d5fc
buyToBorrowETH 0x3ed7d74d
购买 NFT 并与正在拍卖的贷款出价撮合，生成新的借款
使用场景是：当前有一个 loanoffer，但是没有 NFT 与之撮合，买家从交易所中购买 NFT 并与之撮合，生成新的借款，买家成为借款人并获得资金。

https://etherscan.io/address/0x29469395eaf6f95920e59f858042f0e28d98a20b?method=0x8593d5fc
https://etherscan.io/address/0x29469395eaf6f95920e59f858042f0e28d98a20b?method=0x3ed7d74d

https://dashboard.tenderly.co/tx/mainnet/0x6b08a227ce9042fb36ae12e0c0fd81ded630c86dcc33851219f529bacce6f311/logs

buyToBorrowLocked 0x2e2fb18b
buyToBorrowLockedETH 0xb2a0bb86
购买被抵押的 NFT，还清贷款，然后与指定的贷款出价撮合，生成新的借款
使用场景是：当前有一个 selloffer，和一个 loanoffer。买家接受 selloffer，购买 NFT，替之前的借款人还清贷款，接着与 loanoffer 撮合，生成新的借款，买家成为借款人获得资金。

https://etherscan.io/address/0x29469395eaf6f95920e59f858042f0e28d98a20b?method=0x2e2fb18b
https://etherscan.io/address/0x29469395eaf6f95920e59f858042f0e28d98a20b?method=0xb2a0bb86

buyLocked 0xe7efc178
buyLockedETH 0x8553b234
购买被抵押的 NFT，替借款人还清贷款
使用场景是：当前有一个 selloffer，买家接受 selloffer，购买 NFT。然后替借款人还清贷款。

https://etherscan.io/address/0x29469395eaf6f95920e59f858042f0e28d98a20b?method=0xe7efc178
https://etherscan.io/address/0x29469395eaf6f95920e59f858042f0e28d98a20b?method=0x8553b234