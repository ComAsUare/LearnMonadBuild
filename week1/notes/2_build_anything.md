https://buildanything.so/zh/tracks/freshman/lessons/

1. vibecoding入门
   prompt injection, agent所能读入的一切信息中，混入隐藏指令
   预防：在沙箱中运行智能体
   绝不要把真实的私钥、密码或 API key 交给智能体
    1. 循环
        描述 — 用自然语言告诉智能体你想要什么
        构建 — 智能体编写代码并创建文件
        审视 — 在浏览器里查看它的成果
        反馈 — 告诉智能体需要改什么
        重复 — 不断迭代，直到你满意为止（第一版不会满意）
2. 生产级品质代码
    1. 产品细节
        响应式设计（responsive design）； Favicon 与页面标题（favicon & page title）浏览器标签页小图标，搜索页标题；无障碍（accessibility）；深色主题
    2. 被发现
        搜索引擎优化（search engine optimization）;Open Graph tags;访问数据分析；自定义域名
    复杂部分：
    3. 真实功能
        1. 数据库：应用的记忆。Supabase、Firebase、PlanetScale
        2. 用户认证（user authentication）。让用户能创建账号并登录。这包括密码哈希、会话管理、OAuth（用 Google 登录）、邮箱验证和密码重置。永远不要从零自己实现这一套
        3. 文件存储（file storage） 云存储。如果存储在服务器，每次重新部署会清空。
        4. 支付。 比如stripe这样支付服务商，处理信用卡、税费、收据和退款。它们每笔大约抽 3%，并且有可能冻结你的账户。
    4. 基础设施
        环境变量，ci/cd, 预发布环境
    5. 可靠性
        error handling； error tracking ：sentry；testing; backup
    6. 安全
        HTTP应用和用户流量加密； input validation; rate limiting
    7. 优化
        image 压缩；caching;浏览器缓存、服务器缓存、CDN 缓存;
        Core Web Vitals —— Google 用来衡量页面速度和用户体验的指标。它们会直接影响你的搜索排名。
3. 行业尚未被构建
    抗审查的工具
    可验证的身份和投票系统
    由用户真正掌控的数据隐私
    不容易被伪造的 AI 内容识别
    不容易被少数人操控的治理系统
    不会被平台随意收回的所有权
4. 10000tps
    1. amm是慢链下不得不的选择，订单簿上链
    2. 链游：脱离开发者运行，玩家历史永久公开，物品跨游戏，跨defi使用
    3. 社交：Farcaster 和 Lens ；继续把交互数据上链。
    
    4. 哪些数据留在链下：
        私密数据，不宜公开数据，大文件留在链下。哈希适合上链；文件本身的字节，应该放进真正为字节存储设计的系统里。

        超高频事件留在链下。每秒几十万次更新的传感器数据流，不属于任何一条链。

        重计算留在链下。链负责共识和归属权，不负责视频转码，也不负责 AI 推理。

        如果某类交互本来就可以信任一个运营者，它也应该留在链下。一个应用如果能接受自己的排序器、撮合器或游戏服务器，就没有必要把链塞进这条路径。

        划分原则没有变：需要无信任、永久性、可组合性的部分上链，其余部分留在链下。变化的是这条线会落在新的位置，而不是这条线不再存在。
5. 数据库
    数据库和存储是攻击者最先盯上的地方——用户数据就放在那里。
    1。组织
        users, todos, projects(这个表是如何组织todos)
    2. SQL
        Structured Query Language,
        SELECT 读取行
        INSERT 添加一行
        UPDATE 修改已有的行
        DELETE 删除行
    3. 文件存储
        数据库适合结构化存储（文本、数字、日期、各种关系）
        云端存储：头像和个人资料图片
        用户上传的图片、视频、音频、PDF
        各种导出文件、报表和生成文件
        

