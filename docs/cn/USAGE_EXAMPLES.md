# 🚀 Move 安全模组使用示例集

本文档提供了 Move 安全模组的实际使用示例，帮助开发者快速集成和使用。

## 📖 目录

1. [快速开始](#1-快速开始)
2. [DeFi 应用示例](#2-defi-应用示例)
3. [NFT 市场示例](#3-nft-市场示例)
4. [游戏应用示例](#4-游戏应用示例)
5. [DAO 治理示例](#5-dao-治理示例)
6. [集成测试示例](#6-集成测试示例)

---

## 1. 快速开始

### 1.1 基础合约模板

```move
module my_project::secure_contract {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use std::signer;
    use std::string;
    
    // 角色定义
    const OPERATOR_ROLE: vector<u8> = b"OPERATOR_ROLE";
    
    // 初始化函数
    public fun initialize(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // 基础安全模组初始化
        ownable::initialize(deployer);
        access_control::initialize(deployer);
        pausable::initialize(deployer);
        
        // 设置操作员角色
        let operator_role = string::utf8(OPERATOR_ROLE);
        access_control::grant_role(deployer, deployer_addr, operator_role, deployer_addr);
    }
    
    // 受保护的函数示例
    public fun protected_operation(caller: &signer, contract_addr: address, value: u64) {
        // 安全检查
        pausable::when_not_paused(contract_addr);
        access_control::only_role(caller, contract_addr, string::utf8(OPERATOR_ROLE));
        
        // 业务逻辑
        execute_operation(value);
    }
    
    // 所有者专用函数
    public fun admin_operation(owner: &signer, contract_addr: address) {
        ownable::only_owner(owner, contract_addr);
        // 管理员操作
    }
    
    // 紧急暂停
    public fun emergency_pause(admin: &signer, contract_addr: address) {
        ownable::only_owner(admin, contract_addr);
        pausable::emergency_pause(admin, contract_addr);
    }
    
    fun execute_operation(value: u64) {
        // 实际业务逻辑
    }
}
```

### 1.2 最小化集成

```move
module simple::vault {
    use ownable::ownable;
    use pausable::pausable;
    use aptos_framework::coin;
    
    public fun initialize(owner: &signer) {
        ownable::initialize(owner);
        pausable::initialize(owner);
    }
    
    public fun deposit<CoinType>(
        user: &signer, 
        contract_addr: address, 
        amount: u64
    ) {
        pausable::when_not_paused(contract_addr);
        let coins = coin::withdraw<CoinType>(user, amount);
        coin::deposit(contract_addr, coins);
    }
    
    public fun withdraw<CoinType>(
        owner: &signer,
        contract_addr: address,
        amount: u64
    ) {
        ownable::only_owner(owner, contract_addr);
        pausable::when_not_paused(contract_addr);
        
        let coins = coin::withdraw<CoinType>(owner, amount);
        coin::deposit(signer::address_of(owner), coins);
    }
}
```

---

## 2. DeFi 应用示例

### 2.1 去中心化借贷协议

```move
module defi::lending_protocol {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use block_limiter::block_limiter;
    use std::string;
    use aptos_framework::coin;
    use aptos_framework::event;
    
    // 角色定义
    const LIQUIDATOR_ROLE: vector<u8> = b"LIQUIDATOR_ROLE";
    const ORACLE_ROLE: vector<u8> = b"ORACLE_ROLE";
    const RISK_MANAGER_ROLE: vector<u8> = b"RISK_MANAGER_ROLE";
    
    // 事件
    #[event]
    struct DepositEvent has drop, store {
        user: address,
        amount: u64,
        timestamp: u64,
    }
    
    #[event]
    struct LiquidationEvent has drop, store {
        liquidator: address,
        borrower: address,
        collateral_amount: u64,
        debt_amount: u64,
    }
    
    // 借贷配置
    struct LendingConfig has key {
        collateral_ratio: u64,
        liquidation_threshold: u64,
        interest_rate: u64,
    }
    
    // 用户仓位
    struct UserPosition has key {
        collateral: u64,
        debt: u64,
        last_update: u64,
    }
    
    // 初始化借贷协议
    public fun initialize_lending(
        deployer: &signer,
        oracle_addr: address,
        liquidator_addr: address
    ) {
        let deployer_addr = signer::address_of(deployer);
        
        // 安全模组初始化
        ownable::initialize(deployer);
        access_control::initialize(deployer);
        pausable::initialize(deployer);
        
        // 访问频率限制：每10个区块最多5次操作
        block_limiter::initialize(
            deployer,
            5,          // max_accesses_per_block_window
            10,         // block_window_size
            3,          // max_accesses_per_time_window
            300000000,  // time_window_size (5分钟)
            2,          // block_cooldown
            60000000    // time_cooldown (1分钟)
        );
        
        // 角色分配
        let liquidator_role = string::utf8(LIQUIDATOR_ROLE);
        let oracle_role = string::utf8(ORACLE_ROLE);
        let risk_manager_role = string::utf8(RISK_MANAGER_ROLE);
        
        access_control::grant_role(deployer, deployer_addr, liquidator_role, liquidator_addr);
        access_control::grant_role(deployer, deployer_addr, oracle_role, oracle_addr);
        access_control::grant_role(deployer, deployer_addr, risk_manager_role, deployer_addr);
        
        // 初始化配置
        move_to(deployer, LendingConfig {
            collateral_ratio: 150, // 150%
            liquidation_threshold: 120, // 120%
            interest_rate: 5, // 5%
        });
    }
    
    // 存款抵押
    public fun deposit_collateral<CollateralType>(
        user: &signer,
        contract_addr: address,
        amount: u64
    ) acquires UserPosition {
        // 安全检查
        pausable::when_not_paused(contract_addr);
        block_limiter::require_access(user, contract_addr);
        
        let user_addr = signer::address_of(user);
        
        // 收取抵押品
        let collateral = coin::withdraw<CollateralType>(user, amount);
        coin::deposit(contract_addr, collateral);
        
        // 更新用户仓位
        if (!exists<UserPosition>(user_addr)) {
            move_to(user, UserPosition {
                collateral: amount,
                debt: 0,
                last_update: timestamp::now_microseconds(),
            });
        } else {
            let position = borrow_global_mut<UserPosition>(user_addr);
            position.collateral = position.collateral + amount;
            position.last_update = timestamp::now_microseconds();
        };
        
        // 发出事件
        event::emit(DepositEvent {
            user: user_addr,
            amount,
            timestamp: timestamp::now_microseconds(),
        });
    }
    
    // 借款
    public fun borrow<DebtType>(
        user: &signer,
        contract_addr: address,
        amount: u64
    ) acquires UserPosition, LendingConfig {
        pausable::when_not_paused(contract_addr);
        block_limiter::require_access(user, contract_addr);
        
        let user_addr = signer::address_of(user);
        let position = borrow_global_mut<UserPosition>(user_addr);
        let config = borrow_global<LendingConfig>(contract_addr);
        
        // 检查抵押率
        let new_debt = position.debt + amount;
        let required_collateral = (new_debt * config.collateral_ratio) / 100;
        assert!(position.collateral >= required_collateral, 1);
        
        // 更新债务
        position.debt = new_debt;
        position.last_update = timestamp::now_microseconds();
        
        // 发放借款
        let debt_coins = coin::withdraw<DebtType>(&get_treasury_signer(), amount);
        coin::deposit(user_addr, debt_coins);
    }
    
    // 清算
    public fun liquidate<CollateralType, DebtType>(
        liquidator: &signer,
        contract_addr: address,
        borrower_addr: address,
        debt_amount: u64
    ) acquires UserPosition, LendingConfig {
        pausable::when_not_paused(contract_addr);
        access_control::only_role(liquidator, contract_addr, string::utf8(LIQUIDATOR_ROLE));
        
        let position = borrow_global_mut<UserPosition>(borrower_addr);
        let config = borrow_global<LendingConfig>(contract_addr);
        
        // 检查是否可清算
        let liquidation_collateral = (position.debt * config.liquidation_threshold) / 100;
        assert!(position.collateral < liquidation_collateral, 2);
        
        // 执行清算
        let repay_coins = coin::withdraw<DebtType>(liquidator, debt_amount);
        coin::deposit(contract_addr, repay_coins);
        
        // 计算清算奖励
        let liquidation_reward = (debt_amount * 105) / 100; // 5% 奖励
        let reward_coins = coin::withdraw<CollateralType>(&get_treasury_signer(), liquidation_reward);
        coin::deposit(signer::address_of(liquidator), reward_coins);
        
        // 更新仓位
        position.debt = position.debt - debt_amount;
        position.collateral = position.collateral - liquidation_reward;
        
        event::emit(LiquidationEvent {
            liquidator: signer::address_of(liquidator),
            borrower: borrower_addr,
            collateral_amount: liquidation_reward,
            debt_amount,
        });
    }
    
    // 更新风险参数 - 仅风险管理员
    public fun update_risk_parameters(
        risk_manager: &signer,
        contract_addr: address,
        new_collateral_ratio: u64,
        new_liquidation_threshold: u64
    ) acquires LendingConfig {
        access_control::only_role(risk_manager, contract_addr, string::utf8(RISK_MANAGER_ROLE));
        
        let config = borrow_global_mut<LendingConfig>(contract_addr);
        config.collateral_ratio = new_collateral_ratio;
        config.liquidation_threshold = new_liquidation_threshold;
    }
    
    // 紧急暂停 - 仅所有者
    public fun emergency_pause(owner: &signer, contract_addr: address) {
        ownable::only_owner(owner, contract_addr);
        pausable::emergency_pause(owner, contract_addr);
    }
    
    fun get_treasury_signer(): signer {
        // 实现获取国库签名者的逻辑
        // 这里需要根据具体实现调整
        abort 999
    }
}
```

### 2.2 自动做市商 (AMM)

```move
module defi::amm {
    use ownable::ownable;
    use pausable::pausable;
    use block_limiter::block_limiter;
    use aptos_framework::coin;
    use std::signer;
    
    // 流动性池
    struct LiquidityPool<phantom X, phantom Y> has key {
        reserve_x: u64,
        reserve_y: u64,
        total_supply: u64,
    }
    
    // LP 代币
    struct LPToken<phantom X, phantom Y> has key {
        amount: u64,
    }
    
    // 初始化 AMM
    public fun initialize_amm(deployer: &signer) {
        ownable::initialize(deployer);
        pausable::initialize(deployer);
        
        // 设置交易频率限制
        block_limiter::initialize(
            deployer,
            10,         // 每个区块窗口最多10次交易
            5,          // 5个区块窗口
            20,         // 每个时间窗口最多20次交易
            60000000,   // 1分钟时间窗口
            1,          // 1个区块冷却期
            10000000    // 10秒时间冷却期
        );
    }
    
    // 创建流动性池
    public fun create_pool<X, Y>(
        creator: &signer,
        contract_addr: address,
        initial_x: u64,
        initial_y: u64
    ) {
        ownable::only_owner(creator, contract_addr);
        pausable::when_not_paused(contract_addr);
        
        // 收集初始流动性
        let coins_x = coin::withdraw<X>(creator, initial_x);
        let coins_y = coin::withdraw<Y>(creator, initial_y);
        
        // 存储到合约
        coin::deposit(contract_addr, coins_x);
        coin::deposit(contract_addr, coins_y);
        
        // 创建流动性池
        move_to(creator, LiquidityPool<X, Y> {
            reserve_x: initial_x,
            reserve_y: initial_y,
            total_supply: (initial_x * initial_y) / 1000, // 简化的 LP 计算
        });
    }
    
    // 代币交换
    public fun swap<X, Y>(
        trader: &signer,
        contract_addr: address,
        amount_in: u64,
        min_amount_out: u64
    ) acquires LiquidityPool {
        pausable::when_not_paused(contract_addr);
        block_limiter::require_access(trader, contract_addr);
        
        let pool = borrow_global_mut<LiquidityPool<X, Y>>(contract_addr);
        
        // 计算输出金额 (简化的 AMM 公式)
        let amount_out = (amount_in * pool.reserve_y) / (pool.reserve_x + amount_in);
        assert!(amount_out >= min_amount_out, 1);
        
        // 执行交换
        let coins_in = coin::withdraw<X>(trader, amount_in);
        coin::deposit(contract_addr, coins_in);
        
        let coins_out = coin::withdraw<Y>(&get_treasury_signer(), amount_out);
        coin::deposit(signer::address_of(trader), coins_out);
        
        // 更新储备
        pool.reserve_x = pool.reserve_x + amount_in;
        pool.reserve_y = pool.reserve_y - amount_out;
    }
    
    fun get_treasury_signer(): signer {
        abort 999 // 实现细节
    }
}
```

---

## 3. NFT 市场示例

### 3.1 NFT 交易市场

```move
module nft::marketplace {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use capability_store::capability_store;
    use std::string::{Self, String};
    use std::signer;
    use std::vector;
    use aptos_framework::event;
    
    // 特殊能力定义
    struct VIPTraderCapability has key, store, drop {
        tier: u8,           // VIP 等级
        discount_rate: u64, // 折扣率
        daily_limit: u64,   // 每日交易限额
    }
    
    struct CuratorCapability has key, store, drop {
        max_collections: u64,    // 最大策展收藏数
        commission_rate: u64,    // 佣金率
        verified: bool,          // 是否认证
    }
    
    // 角色定义
    const CURATOR_ROLE: vector<u8> = b"CURATOR_ROLE";
    const MODERATOR_ROLE: vector<u8> = b"MODERATOR_ROLE";
    const ARTIST_ROLE: vector<u8> = b"ARTIST_ROLE";
    
    // NFT 信息
    struct NFTInfo has key, store {
        id: u64,
        creator: address,
        owner: address,
        metadata_uri: String,
        royalty_rate: u64,
        price: u64,
        for_sale: bool,
    }
    
    // 收藏信息
    struct Collection has key {
        name: String,
        creator: address,
        nfts: vector<u64>,
        total_volume: u64,
        verified: bool,
    }
    
    // 市场统计
    struct MarketStats has key {
        total_sales: u64,
        total_volume: u64,
        active_listings: u64,
    }
    
    // 事件
    #[event]
    struct NFTMinted has drop, store {
        id: u64,
        creator: address,
        collection: String,
        metadata_uri: String,
    }
    
    #[event]
    struct NFTSold has drop, store {
        id: u64,
        seller: address,
        buyer: address,
        price: u64,
        royalty_paid: u64,
    }
    
    // 初始化 NFT 市场
    public fun initialize_marketplace(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // 基础安全模组
        ownable::initialize(deployer);
        access_control::initialize(deployer);
        pausable::initialize(deployer);
        capability_store::initialize(deployer);
        
        // 角色设置
        let curator_role = string::utf8(CURATOR_ROLE);
        let moderator_role = string::utf8(MODERATOR_ROLE);
        let artist_role = string::utf8(ARTIST_ROLE);
        
        access_control::grant_role(deployer, deployer_addr, curator_role, deployer_addr);
        access_control::grant_role(deployer, deployer_addr, moderator_role, deployer_addr);
        
        // 初始化市场统计
        move_to(deployer, MarketStats {
            total_sales: 0,
            total_volume: 0,
            active_listings: 0,
        });
    }
    
    // 创建收藏 - 需要策展人能力
    public fun create_collection(
        creator: &signer,
        contract_addr: address,
        name: String,
        metadata_uri: String
    ) {
        pausable::when_not_paused(contract_addr);
        
        // 检查策展人角色和能力
        access_control::only_role(creator, contract_addr, string::utf8(CURATOR_ROLE));
        capability_store::assert_capability<CuratorCapability>(creator);
        
        // 创建收藏
        move_to(creator, Collection {
            name,
            creator: signer::address_of(creator),
            nfts: vector::empty<u64>(),
            total_volume: 0,
            verified: false,
        });
    }
    
    // 铸造 NFT
    public fun mint_nft(
        creator: &signer,
        contract_addr: address,
        metadata_uri: String,
        royalty_rate: u64,
        initial_price: u64
    ): u64 acquires MarketStats {
        pausable::when_not_paused(contract_addr);
        access_control::only_role(creator, contract_addr, string::utf8(ARTIST_ROLE));
        
        let creator_addr = signer::address_of(creator);
        
        // 生成 NFT ID
        let stats = borrow_global_mut<MarketStats>(contract_addr);
        let nft_id = stats.total_sales + 1; // 简化的 ID 生成
        
        // 创建 NFT
        move_to(creator, NFTInfo {
            id: nft_id,
            creator: creator_addr,
            owner: creator_addr,
            metadata_uri,
            royalty_rate,
            price: initial_price,
            for_sale: true,
        });
        
        // 更新统计
        stats.active_listings = stats.active_listings + 1;
        
        // 发出事件
        event::emit(NFTMinted {
            id: nft_id,
            creator: creator_addr,
            collection: string::utf8(b"default"),
            metadata_uri,
        });
        
        nft_id
    }
    
    // VIP 购买 - 享受折扣
    public fun vip_purchase(
        buyer: &signer,
        contract_addr: address,
        nft_id: u64,
        seller_addr: address
    ) acquires NFTInfo, MarketStats {
        pausable::when_not_paused(contract_addr);
        
        // 检查 VIP 能力
        capability_store::assert_capability<VIPTraderCapability>(buyer);
        
        let buyer_addr = signer::address_of(buyer);
        let nft = borrow_global_mut<NFTInfo>(seller_addr);
        assert!(nft.for_sale, 1);
        assert!(nft.id == nft_id, 2);
        
        // 获取 VIP 折扣
        let (_, _, _) = capability_store::get_capability_metadata<VIPTraderCapability>(buyer_addr);
        let discounted_price = (nft.price * 95) / 100; // 5% 折扣
        
        // 计算版税
        let royalty = (discounted_price * nft.royalty_rate) / 10000;
        let seller_amount = discounted_price - royalty;
        
        // 执行购买（这里简化了支付逻辑）
        purchase_nft_internal(buyer, seller_addr, nft, discounted_price, royalty, seller_amount, contract_addr);
    }
    
    // 普通购买
    public fun purchase_nft(
        buyer: &signer,
        contract_addr: address,
        nft_id: u64,
        seller_addr: address
    ) acquires NFTInfo, MarketStats {
        pausable::when_not_paused(contract_addr);
        
        let nft = borrow_global_mut<NFTInfo>(seller_addr);
        assert!(nft.for_sale, 1);
        assert!(nft.id == nft_id, 2);
        
        let price = nft.price;
        let royalty = (price * nft.royalty_rate) / 10000;
        let seller_amount = price - royalty;
        
        purchase_nft_internal(buyer, seller_addr, nft, price, royalty, seller_amount, contract_addr);
    }
    
    // 内部购买逻辑
    fun purchase_nft_internal(
        buyer: &signer,
        seller_addr: address,
        nft: &mut NFTInfo,
        total_price: u64,
        royalty: u64,
        seller_amount: u64,
        contract_addr: address
    ) acquires MarketStats {
        let buyer_addr = signer::address_of(buyer);
        
        // 转移所有权
        nft.owner = buyer_addr;
        nft.for_sale = false;
        
        // 更新市场统计
        let stats = borrow_global_mut<MarketStats>(contract_addr);
        stats.total_sales = stats.total_sales + 1;
        stats.total_volume = stats.total_volume + total_price;
        stats.active_listings = stats.active_listings - 1;
        
        // 发出销售事件
        event::emit(NFTSold {
            id: nft.id,
            seller: seller_addr,
            buyer: buyer_addr,
            price: total_price,
            royalty_paid: royalty,
        });
    }
    
    // 授予 VIP 能力
    public fun grant_vip_status(
        owner: &signer,
        contract_addr: address,
        user_addr: address,
        tier: u8,
        discount_rate: u64,
        daily_limit: u64
    ) {
        ownable::only_owner(owner, contract_addr);
        
        let vip_capability = VIPTraderCapability {
            tier,
            discount_rate,
            daily_limit,
        };
        
        capability_store::grant_capability(
            owner,
            user_addr,
            vip_capability,
            false // VIP 能力不可委托
        );
    }
    
    // 授予策展人能力
    public fun grant_curator_capability(
        owner: &signer,
        contract_addr: address,
        user_addr: address,
        max_collections: u64,
        commission_rate: u64
    ) {
        ownable::only_owner(owner, contract_addr);
        
        // 先授予角色
        access_control::grant_role(
            owner, 
            contract_addr, 
            string::utf8(CURATOR_ROLE), 
            user_addr
        );
        
        // 再授予能力
        let curator_capability = CuratorCapability {
            max_collections,
            commission_rate,
            verified: true,
        };
        
        capability_store::grant_capability(
            owner,
            user_addr,
            curator_capability,
            true // 策展人能力可委托
        );
    }
    
    // 紧急暂停
    public fun emergency_pause(owner: &signer, contract_addr: address) {
        ownable::only_owner(owner, contract_addr);
        pausable::emergency_pause(owner, contract_addr);
    }
    
    // 内容审核 - 仅管理员
    public fun moderate_content(
        moderator: &signer,
        contract_addr: address,
        nft_id: u64,
        action: u8 // 1: approve, 2: reject, 3: flag
    ) {
        access_control::only_role(moderator, contract_addr, string::utf8(MODERATOR_ROLE));
        // 审核逻辑
    }
}
```

---

## 4. 游戏应用示例

### 4.1 区块链游戏道具系统

```move
module game::item_system {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use capability_store::capability_store;
    use std::string::{Self, String};
    use std::vector;
    use std::signer;
    use aptos_framework::event;
    
    // 游戏能力
    struct GameMasterCapability has key, store, drop {
        level: u8,
        permissions: vector<String>,
    }
    
    struct RareItemCraftCapability has key, store, drop {
        item_types: vector<u64>,
        max_crafts_per_day: u64,
    }
    
    struct GuildLeaderCapability has key, store, drop {
        guild_id: u64,
        member_limit: u64,
    }
    
    // 角色定义
    const GAME_MASTER_ROLE: vector<u8> = b"GAME_MASTER";
    const CRAFTER_ROLE: vector<u8> = b"CRAFTER";
    const GUILD_LEADER_ROLE: vector<u8> = b"GUILD_LEADER";
    
    // 游戏道具
    struct GameItem has key, store {
        id: u64,
        item_type: u64,     // 1: weapon, 2: armor, 3: consumable, 4: rare
        rarity: u8,         // 1-5 星级
        attributes: vector<u64>,
        durability: u64,
        owner: address,
        tradeable: bool,
    }
    
    // 玩家信息
    struct PlayerInfo has key {
        level: u64,
        experience: u64,
        inventory: vector<u64>, // item IDs
        guild_id: u64,
        crafting_cooldown: u64,
    }
    
    // 公会信息
    struct Guild has key {
        id: u64,
        name: String,
        leader: address,
        members: vector<address>,
        treasury: u64,
        level: u64,
    }
    
    // 事件
    #[event]
    struct ItemCrafted has drop, store {
        player: address,
        item_id: u64,
        item_type: u64,
        rarity: u8,
    }
    
    #[event]
    struct ItemTraded has drop, store {
        from: address,
        to: address,
        item_id: u64,
        price: u64,
    }
    
    // 初始化游戏系统
    public fun initialize_game(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // 安全模组初始化
        ownable::initialize(deployer);
        access_control::initialize(deployer);
        pausable::initialize(deployer);
        capability_store::initialize(deployer);
        
        // 设置游戏管理员角色
        let gm_role = string::utf8(GAME_MASTER_ROLE);
        access_control::grant_role(deployer, deployer_addr, gm_role, deployer_addr);
        
        // 授予游戏管理员能力
        let gm_capability = GameMasterCapability {
            level: 10,
            permissions: vector[
                string::utf8(b"CREATE_ITEMS"),
                string::utf8(b"MODIFY_PLAYERS"),
                string::utf8(b"MANAGE_GUILDS")
            ],
        };
        
        capability_store::grant_capability(
            deployer,
            deployer_addr,
            gm_capability,
            true
        );
    }
    
    // 玩家注册
    public fun register_player(player: &signer, contract_addr: address) {
        pausable::when_not_paused(contract_addr);
        
        let player_addr = signer::address_of(player);
        
        move_to(player, PlayerInfo {
            level: 1,
            experience: 0,
            inventory: vector::empty<u64>(),
            guild_id: 0,
            crafting_cooldown: 0,
        });
        
        // 初始化玩家的能力存储
        capability_store::initialize(player);
    }
    
    // 制作普通道具
    public fun craft_item(
        player: &signer,
        contract_addr: address,
        item_type: u64,
        materials: vector<u64>
    ) acquires PlayerInfo {
        pausable::when_not_paused(contract_addr);
        access_control::only_role(player, contract_addr, string::utf8(CRAFTER_ROLE));
        
        let player_addr = signer::address_of(player);
        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        
        // 检查冷却时间
        assert!(player_info.crafting_cooldown < timestamp::now_microseconds(), 1);
        
        // 制作道具
        let item_id = generate_item_id();
        let rarity = calculate_rarity(player_info.level, materials);
        
        let item = GameItem {
            id: item_id,
            item_type,
            rarity,
            attributes: calculate_attributes(item_type, rarity),
            durability: 100,
            owner: player_addr,
            tradeable: true,
        };
        
        // 存储道具
        move_to(player, item);
        vector::push_back(&mut player_info.inventory, item_id);
        
        // 设置冷却时间
        player_info.crafting_cooldown = timestamp::now_microseconds() + 3600000000; // 1小时
        
        event::emit(ItemCrafted {
            player: player_addr,
            item_id,
            item_type,
            rarity,
        });
    }
    
    // 制作稀有道具 - 需要特殊能力
    public fun craft_legendary_item(
        player: &signer,
        contract_addr: address,
        item_type: u64,
        special_materials: vector<u64>
    ) acquires PlayerInfo {
        pausable::when_not_paused(contract_addr);
        
        // 检查制作能力
        capability_store::assert_capability<RareItemCraftCapability>(player);
        
        let player_addr = signer::address_of(player);
        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        
        // 制作传说道具
        let item_id = generate_item_id();
        let item = GameItem {
            id: item_id,
            item_type,
            rarity: 5, // 传说级
            attributes: calculate_legendary_attributes(item_type, special_materials),
            durability: 200,
            owner: player_addr,
            tradeable: false, // 传说道具不可交易
        };
        
        move_to(player, item);
        vector::push_back(&mut player_info.inventory, item_id);
        
        event::emit(ItemCrafted {
            player: player_addr,
            item_id,
            item_type,
            rarity: 5,
        });
    }
    
    // 道具交易
    public fun trade_item(
        seller: &signer,
        buyer: &signer,
        contract_addr: address,
        item_id: u64,
        price: u64
    ) acquires GameItem, PlayerInfo {
        pausable::when_not_paused(contract_addr);
        
        let seller_addr = signer::address_of(seller);
        let buyer_addr = signer::address_of(buyer);
        
        // 验证道具所有权和可交易性
        let item = borrow_global_mut<GameItem>(seller_addr);
        assert!(item.id == item_id, 1);
        assert!(item.owner == seller_addr, 2);
        assert!(item.tradeable, 3);
        
        // 执行交易（简化支付逻辑）
        item.owner = buyer_addr;
        
        // 更新库存
        let seller_info = borrow_global_mut<PlayerInfo>(seller_addr);
        let buyer_info = borrow_global_mut<PlayerInfo>(buyer_addr);
        
        // 从卖家库存中移除
        let (found, index) = vector::index_of(&seller_info.inventory, &item_id);
        if (found) {
            vector::remove(&mut seller_info.inventory, index);
        };
        
        // 添加到买家库存
        vector::push_back(&mut buyer_info.inventory, item_id);
        
        event::emit(ItemTraded {
            from: seller_addr,
            to: buyer_addr,
            item_id,
            price,
        });
    }
    
    // 创建公会 - 需要公会领导能力
    public fun create_guild(
        leader: &signer,
        contract_addr: address,
        guild_name: String
    ) acquires PlayerInfo {
        pausable::when_not_paused(contract_addr);
        capability_store::assert_capability<GuildLeaderCapability>(leader);
        
        let leader_addr = signer::address_of(leader);
        let guild_id = generate_guild_id();
        
        let guild = Guild {
            id: guild_id,
            name: guild_name,
            leader: leader_addr,
            members: vector[leader_addr],
            treasury: 0,
            level: 1,
        };
        
        move_to(leader, guild);
        
        // 更新玩家公会信息
        let player_info = borrow_global_mut<PlayerInfo>(leader_addr);
        player_info.guild_id = guild_id;
    }
    
    // 授予稀有道具制作能力
    public fun grant_rare_craft_ability(
        gm: &signer,
        contract_addr: address,
        player_addr: address,
        item_types: vector<u64>,
        daily_limit: u64
    ) {
        capability_store::assert_capability<GameMasterCapability>(gm);
        
        let craft_capability = RareItemCraftCapability {
            item_types,
            max_crafts_per_day: daily_limit,
        };
        
        capability_store::grant_capability(
            gm,
            player_addr,
            craft_capability,
            false
        );
    }
    
    // 紧急维护
    public fun emergency_maintenance(owner: &signer, contract_addr: address) {
        ownable::only_owner(owner, contract_addr);
        pausable::emergency_pause(owner, contract_addr);
    }
    
    // 辅助函数
    fun generate_item_id(): u64 {
        // 简化的 ID 生成
        timestamp::now_microseconds() % 1000000
    }
    
    fun generate_guild_id(): u64 {
        timestamp::now_microseconds() % 10000
    }
    
    fun calculate_rarity(player_level: u64, materials: vector<u64>): u8 {
        // 简化的稀有度计算
        if (player_level >= 50 && vector::length(&materials) >= 5) {
            4 // 史诗
        } else if (player_level >= 30) {
            3 // 稀有
        } else if (player_level >= 10) {
            2 // 优秀
        } else {
            1 // 普通
        }
    }
    
    fun calculate_attributes(item_type: u64, rarity: u8): vector<u64> {
        // 简化的属性计算
        vector[
            (rarity as u64) * 10,  // 攻击力
            (rarity as u64) * 8,   // 防御力
            (rarity as u64) * 5    // 敏捷
        ]
    }
    
    fun calculate_legendary_attributes(item_type: u64, materials: vector<u64>): vector<u64> {
        // 传说道具的特殊属性计算
        vector[100, 80, 60, 40, 20] // 全属性加成
    }
}
```

这个文档提供了从基础集成到复杂应用场景的完整使用示例，帮助开发者理解如何在实际项目中有效使用这些安全模组。每个示例都展示了不同的安全需求和模组组合方式。 