1. 这是个用在dao组织中提案的vote合约
    维护一个struct proposals, 包含proposal_id, intent. 
    starttime， endTime，for_votes, against_botes,  has_voted变量。每次dao有新提案，会在prososals中添加。
    这样的方案好于用工厂合约，每次有新提案生成新合约。以为部署合约的gas成本高昂
2. 权限管理
    1. 提案门槛
        需要管理代币数量达到门槛才能提案投票。DAO实践中普通用户会在论坛中讨论，等到话题热度升高后，委托达到门槛的用户创建提案
    2. 投票代币权重
        普通用户投票和账户余额权重相关，提高利益关切，和治理积极性。 
    3. delegate投票委托
        通过openzepplin erc20vote库实现，让有时间、有专业知识的用户得到委托，避免闪电贷攻击
3. 主要函数有三个
    1. createProposal
        校验提案人账户余额，管理ProposalID
    2  castVote
        选民投票，检查时间，检查是否投过，更新计票
    3.  finalizeProposal —— 结算投票
        检查时间，结果判定

4. foundry测试
    vm语法学习：
    1. vm.startPrank / vm.stopPrank / vm.prank
        模拟以某个地址的身份发交易
    2. vm.warp
        快进区块时间，模拟时间流逝：
    3. vm.expectRevert
        断言下一次调用会 revert（类似 Solidity 的 try-catch）：
    4. vm.expectEmit
        断言下一次调用会触发特定事件：

    5.  makeAddr
        根据字符串生成一个确定性地址