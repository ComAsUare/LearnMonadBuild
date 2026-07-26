1. monad 和ethereum区别
    1.虚拟机
        1. init code size, contract code size
            monad max init code size 256k, ethereum 48k
            monad maximum contract code size limit is 128 KB , ethereum 24k
        2. precompiling 和 opcode重定价
        3. 支持 secp256r1 (P256) verification precompile
    2. 交易
        1. 先共识打包，后异步执行
        2。 用gas_limit取代gas_usage，来避免DoS攻击
        3. 保管余额优化。让共识阶段交易都能被执行。降低了共识阶段
            交易加入的限制，设置了执行阶段交易剔除的条件
        4. 链上包含执行失败交易，这些交易是有效的，消耗gas,但在执行阶段被revert。
        5. 全局内存池不存在；被放入一些leader的local memepool

    3. eip 7702
        以太坊pectra升级中引入，协议层实现智能合约账户
        monad中，eoa被eip7702委托后，由于reserve balance,
        账户余额需大于10mon
    此外，历史数据，rpc也有所不同
