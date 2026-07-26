1. 你是个智能合约编程者，协助我完成一个投票系统solidity合约。
    合约名称：proposalVote.
    添加struct proposal，包含如下变量：uint256 proposal_id, address proposer, string proposal_intent, uint256 start_time, uint256 end_time, uint 256 for_votes, uint256 against_botes, mapping(address=>bool) has_voted.
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
4.  草稿解释：
    1. interface IGovernanceToken dao治理代币
    2. error VotingNotActive  还没到投票开始时间
5. require改为if revert更好
6. 生成remix编译部署调试测试步骤，以及预期结果
7. 进行forge的本地测试。 给出foundry项目配置和测试覆盖列表。
    要详细把/test/ProposalVote.t.sol中覆盖的每一个测试内容列出来，总结在testRecord.md文件中。

