# ProposalVote 测试覆盖清单

## 测试环境 `setUp()`

部署 `GovernanceToken`（ERC20 + ERC20Votes），给 alice / bob / carol 各 mint 1,000,000 GOV，三人各自 delegate 给自己激活投票权重，随后部署 `ProposalVote`（投票门槛 = 1 wei）。每条用例都从干净的链状态开始。

---

## 一、初始状态

### `test_InitialState`

部署后读取状态变量，断言 `proposalCount == 0`、`proposalThreshold == 1`、`governanceToken` 指向正确的代币地址。

### `test_Constructor_RevertZeroTokenAddress`

传入 `address(0)` 构造合约，断言 revert `InvalidGovernanceTokenAddress`，确保不允许零地址。

---

## 二、创建提案 `createProposal`

### `test_CreateProposal_Success`

Alice 以 7 天投票期创建提案。断言 `proposalCount == 1`，并通过 `getProposalSummary(1)` 校验全部 8 个返回字段：`proposalId`、`proposer`、`proposalIntent`、`startTime`、`endTime`、`forVotes`、`againstVotes`、`executed`。

### `test_CreateProposal_MultipleProposals`

Alice 连续创建 3 个提案。断言 `proposalCount == 3`，三个提案的 `proposalIntent` 各自独立、ID 递增。

### `test_CreateProposal_RevertBelowThreshold`

nobody（无代币、无投票权重）尝试创建提案。断言 revert `BelowProposalThreshold(nobody, 0, 1)`。

---

## 三、投票 `castVote`

### `test_CastVote_For`

Alice 创建提案后投赞成票。断言 `hasVoted(1, alice) == true`，`forVotes` 等于全部投票权重，`againstVotes == 0`。

### `test_CastVote_Against`

Alice 创建提案后投反对票。断言 `forVotes == 0`，`againstVotes` 等于全部投票权重。

### `test_CastVote_RevertAlreadyVoted`

Alice 投票后立即再次投票。第二次断言 revert `AlreadyVoted(1, alice)`，确保不可重复投票。

### `test_CastVote_RevertProposalNotExist`

对不存在的 proposalId=999 投票。断言 revert `ProposalNotExist(999)`。

### `test_CastVote_RevertVotingEnded`

提案投票期 1 小时，`vm.warp` 快进到 2 小时后投票。断言 revert `VotingNotActive`，确保过期不可再投。

### `test_CastVote_MultipleVoters`

alice + bob 投赞成，carol 投反对。断言 `forVotes == 2 × MINT_AMOUNT`、`againstVotes == 1 × MINT_AMOUNT`，三人 `hasVoted` 全部为 true。

---

## 四、已投票查询 `hasVoted`

### `test_HasVoted_False`

无任何投票记录的提案，断言 `hasVoted(1, alice) == false`。

### `test_HasVoted_True`

投票后再查询，断言 `hasVoted(1, alice) == true`。

---

## 五、提案摘要查询 `getProposalSummary`

### `test_GetProposalSummary_ReturnsCorrectData`

创建提案后获取 8 元组返回值，断言所有字段与创建时的参数一致。

---

## 六、结案 `finalizeProposal`

### `test_FinalizeProposal_Passed`

2 赞成、1 反对，warp 到投票结束后结案。断言 `executed == true`，票数保持不变。

### `test_FinalizeProposal_RevertNotEnded`

投票期 7 天，立即尝试结案。断言 revert `VotingNotEnded(1, currentTime, endTime)`。

### `test_FinalizeProposal_RevertAlreadyFinalized`

warp 过期 → 结案成功 → 再次结案。第二次断言 revert `AlreadyFinalized(1)`。

### `test_FinalizeProposal_RevertNotExist`

对不存在的 proposalId=42 调用结案。断言 revert `ProposalNotExist(42)`。

---

## 七、管理员

### `test_SetProposalThreshold`

更新门槛为 100，断言 `proposalThreshold == 100`。

---

## 八、事件

### `test_EmitProposalCreated`

Alice 创建提案，断言触发 `ProposalCreated` 事件，校验 indexed 的 proposalId / proposer 及 content、时间参数。

### `test_EmitVoteCast`

Alice 投票，断言触发 `VoteCast(1, alice, true, 1_000_000e18)`，校验 indexed 的 proposalId / voter 及 support、weight。

### `test_EmitProposalFinalized`

投票后 warp 过期并结案，断言触发 `ProposalFinalized(1, forVotes, againstVotes, true)`。

---

## 九、集成测试（完整生命周期）

### `test_IntegrationFullLifecycle`

端到端串联六个步骤：

1. **创建提案** → `proposalCount == 1`
2. **三人投票** → alice 赞成、bob 反对、carol 赞成
3. **验证投票状态** → 三人 `hasVoted` 全为 true
4. **warp 过期后结案** → `executed == true`，`forVotes == 2 × MINT_AMOUNT`，`againstVotes == 1 × MINT_AMOUNT`
5. **再创建第二个提案** → `proposalCount == 2`
6. **多次提案不互相干扰** → 验证系统支持反复使用

---

## 覆盖汇总

| 模块 | 用例数 | 覆盖函数 | 覆盖分支 |
|------|--------|---------|---------|
| 初始状态 | 2 | `constructor` | 正常构造、零地址 revert |
| 创建提案 | 3 | `createProposal` | 成功、多提案、门槛不足 revert |
| 投票 | 6 | `castVote` | 赞成/反对、重复投票 revert、不存在 revert、过期 revert、多人投票 |
| hasVoted | 2 | `hasVoted` | true / false 两种路径 |
| getProposalSummary | 1 | `getProposalSummary` | 8 元组返回值校验 |
| 结案 | 4 | `finalizeProposal` | 通过、未结束 revert、重复结案 revert、不存在 revert |
| 管理员 | 1 | `setProposalThreshold` | 正常更新 |
| 事件 | 3 | `ProposalCreated` / `VoteCast` / `ProposalFinalized` | indexed 参数 + 非 indexed 参数 |
| 集成 | 1 | 全部函数 | 完整生命周期 + 多次提案 |
| **合计** | **23** | — | — |
