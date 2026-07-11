ai高效，安全的支付是核心问题；
1.和传统支付场景不同：小额高频支付，agent无身份认证
    速度，凭证(credentials),粒度(granularity): 传统0.5$, agent:0.001micropayment
    agent自动执行，也不会像传统那样每笔交易确认，点击。

2. fluxa产品 端到端ai payment 组件，包括钱包

3. 场景分类：
    *1 a2a
    *2. agent 2 merchant： 2b， 订酒店
    *3. agent 2 tool: 无需订阅，每次api调用，skills, mcp付费
    *4. 转账社交的逻辑。
4. 产品矩阵：
    *1. agent wallet
        一键撤销revoke, 更灵活spending control , offline approval, audit trail.
        钱包场景： 身份证明，拿到bugget，为服务付费，接受支付，把钱花出。
        x402协议与agent
    *2. agent card
        *1. agent card ai 身份认证是为了风控ai幻觉造成乱花钱。
        *2.  finantial harness engineering
    agent风控,固定bugget，一次性。
    *3. agent charge agent收付款。
    *4. 开发者skills. mcp收款
        agent embedded payment protocol. 类似于layer1, layer2。把收款人验证，接受服务放在链下，来提高效率
    *5. user case: 社交，agent红包
    *6  user case: 自动化任务平台
    *7. user case： 订票

