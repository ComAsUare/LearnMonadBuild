1. 你是个智能合约编程者，协助我完成一个投票系统solidity合约。
    合约名称：proposalVote.
    添加struct proposal，包含如下变量：uint256 proposal_id, address proposer, string proposal_intent, uint256 start_time, uint256 end_time, uint 256 for_votes, uint256 against_botes, mapping(address=>bool) has_voted.
2.  草稿解释：
    1. interface IGovernanceToken dao治理代币
    2. error VotingNotActive  还没到投票开始时间
3. require改为if revert更好
4. 生成remix编译部署调试测试步骤，以及预期结果
5. 进行forge的本地测试。 给出foundry项目配置和测试覆盖列表。
    要详细把/test/ProposalVote.t.sol中覆盖的每一个测试内容列出来

