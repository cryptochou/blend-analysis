# blend-analysis



![](classDiagram.svg)


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

buyToBorrow
购买 NFT 并与正在拍卖的贷款出价撮合，生成新的借款
使用场景是：当前有一个 loanoffer，但是没有 NFT 与之撮合，买家从交易所中购买 NFT 并与之撮合，生成新的借款，买家成为借款人并获得资金。

buyToBorrowLocked
购买被抵押的 NFT，还清贷款，然后与指定的贷款出价撮合，生成新的借款
使用场景是：当前有一个 selloffer，和一个 loanoffer。买家接受 selloffer，购买 NFT，替之前的借款人还清贷款，接着与 loanoffer 撮合，生成新的借款，买家成为借款人获得资金。

buyLocked
购买被抵押的 NFT，替借款人还清贷款
使用场景是：当前有一个 selloffer，买家接受 selloffer，购买 NFT。然后替借款人还清贷款。
