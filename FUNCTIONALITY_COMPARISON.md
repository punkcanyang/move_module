# OpenZeppelin 合约与 Move 模块功能对比分析

本文档对比分析了 OpenZeppelin Solidity 合约与我们实现的 Move 模块之间的功能一致性。

## 1. Ownable 模块对比

### OpenZeppelin Ownable.sol 核心功能：
- ✅ `owner()` - 获取当前所有者
- ✅ `transferOwnership(address)` - 转移所有权
- ✅ `renounceOwnership()` - 放弃所有权
- ✅ `onlyOwner` modifier - 仅所有者可调用
- ✅ `OwnershipTransferred` 事件
- ✅ 零地址检查和错误处理

### Move Ownable 模块功能：
- ✅ `owner(address)` - 获取当前所有者
- ✅ `transfer_ownership(signer, address, address)` - 转移所有权
- ✅ `renounce_ownership(signer, address)` - 放弃所有权
- ✅ `only_owner(signer, address)` - 仅所有者检查
- ✅ `OwnershipTransferred` 事件
- ✅ 零地址检查和错误处理
- ✅ 初始化功能（Move 特有）

**功能一致性：✅ 100% 一致**
- 所有核心功能都已实现
- 事件和错误处理保持一致
- Move 版本额外提供了初始化函数

## 2. AccessControl 模块对比

### OpenZeppelin AccessControl.sol 核心功能：
- ✅ `hasRole(bytes32, address)` - 检查角色
- ✅ `grantRole(bytes32, address)` - 授予角色
- ✅ `revokeRole(bytes32, address)` - 撤销角色
- ✅ `renounceRole(bytes32, address)` - 放弃角色
- ✅ `getRoleAdmin(bytes32)` - 获取角色管理员
- ✅ `onlyRole(bytes32)` modifier - 角色权限检查
- ✅ `DEFAULT_ADMIN_ROLE` 默认管理员角色
- ✅ 角色相关事件：`RoleGranted`, `RoleRevoked`, `RoleAdminChanged`

### Move AccessControl 模块功能：
- ✅ `has_role(address, String, address)` - 检查角色
- ✅ `grant_role(signer, address, String, address)` - 授予角色
- ✅ `revoke_role(signer, address, String, address)` - 撤销角色
- ✅ `renounce_role(signer, address, String)` - 放弃角色
- ✅ `get_role_admin(address, String)` - 获取角色管理员
- ✅ `only_role(signer, address, String)` - 角色权限检查
- ✅ `DEFAULT_ADMIN_ROLE` 默认管理员角色
- ✅ 角色相关事件：`RoleGranted`, `RoleRevoked`, `RoleAdminChanged`

**功能一致性：✅ 100% 一致**
- 所有核心功能都已实现
- 角色管理和权限检查机制完全一致
- 事件和错误处理保持一致

## 3. Pausable 模块对比

### OpenZeppelin Pausable.sol 核心功能：
- ✅ `paused()` - 检查暂停状态
- ✅ `_pause()` - 暂停合约
- ✅ `_unpause()` - 恢复合约
- ✅ `whenNotPaused` modifier - 非暂停时可调用
- ✅ `whenPaused` modifier - 暂停时可调用
- ✅ `Paused`, `Unpaused` 事件
- ✅ 暂停状态错误处理

### Move Pausable 模块功能：
- ✅ `is_paused(address)` - 检查暂停状态
- ✅ `pause(signer, address)` - 暂停合约
- ✅ `unpause(signer, address)` - 恢复合约
- ✅ `when_not_paused(address)` - 非暂停时检查
- ✅ `when_paused(address)` - 暂停时检查
- ✅ `Paused`, `Unpaused` 事件
- ✅ 暂停状态错误处理
- ✅ 初始化功能（Move 特有）

**功能一致性：✅ 100% 一致**
- 所有核心功能都已实现
- 暂停机制和状态检查保持一致
- 事件和错误处理完全对应

## 4. CapabilityStore 模块对比

### OpenZeppelin 对应功能：
❌ **OpenZeppelin 中没有直接对应的 CapabilityStore 概念**

### Move CapabilityStore 模块功能：
- ✅ `grant_capability<T>` - 授予能力
- ✅ `revoke_capability<T>` - 撤销能力
- ✅ `delegate_capability<T>` - 委托能力
- ✅ `has_capability<T>` - 检查能力
- ✅ `assert_capability<T>` - 断言能力
- ✅ 能力委托链追踪
- ✅ 泛型类型安全

**功能独特性：⚠️ Move 特有模块**
- CapabilityStore 是 Move 语言特有的概念
- 利用了 Move 的资源和能力系统优势
- 提供比传统访问控制更灵活的权限管理

## 5. BlockLimiter 模块对比

### Move BlockLimiter 模块功能：
- ✅ `is_access_allowed` - 检查访问权限
- ✅ `record_access` - 记录访问
- ✅ `require_access` - 要求访问权限
- ✅ 基于区块高度的限制
- ✅ 基于时间窗口的限制
- ✅ 访问冷却期管理
- ✅ 管理员配置更新

**功能独特性：⚠️ Move 特有模块**
- BlockLimiter 是基于区块链特性的访问控制
- 提供速率限制和频率控制
- 结合区块高度和时间戳的双重限制

## 总体评估

### ✅ 完全一致的模块（3/5）：
1. **Ownable** - 100% 功能一致
2. **AccessControl** - 100% 功能一致
3. **Pausable** - 100% 功能一致

### ⚠️ Move 特有的模块（2/5）：
4. **CapabilityStore** - Move 语言特有的能力管理系统
5. **BlockLimiter** - 区块链特有的访问频率控制

## 结论

### 优势：
1. **高度一致性**：核心安全模块（Ownable、AccessControl、Pausable）与 OpenZeppelin 完全一致
2. **Move 语言优势**：充分利用了 Move 的资源模型和类型安全特性
3. **扩展功能**：提供了传统 Solidity 合约中没有的高级功能
4. **企业级安全**：完整的事件记录和错误处理机制

### 建议：
1. **文档标注**：在文档中明确标注哪些模块是 OpenZeppelin 标准，哪些是 Move 特有扩展
2. **模块组合**：提供示例展示如何组合使用这些模块
3. **最佳实践**：添加安全使用指南和最佳实践建议

### 最终评分：
- **功能完整性**：5/5 ⭐⭐⭐⭐⭐
- **一致性**：4/5 ⭐⭐⭐⭐（60% 完全一致，40% 为 Move 特有扩展）
- **安全性**：5/5 ⭐⭐⭐⭐⭐
- **可用性**：5/5 ⭐⭐⭐⭐⭐

**总评：优秀** - 在保持 OpenZeppelin 核心功能一致性的基础上，充分发挥了 Move 语言的特色和优势。

---

# 🏗️ Move 模组代码架构详细解说

## 1. **Ownable 模组** - 所有权管理系统 👑

### 核心数据结构
```move
struct OwnershipInfo has key {
    owner: address,
}
```

### 架构特点：
- **资源模型**：利用 Move 的 `key` 能力将所有权信息存储为全局资源
- **线性类型安全**：确保每个合约只能有一个 `OwnershipInfo` 实例
- **地址零值检查**：防止将所有权转移给无效地址 `@0x0`

### 关键功能实现：
```move
// 初始化机制 - 支持两种模式
public fun initialize(account: &signer)                    // 部署者成为所有者
public fun initialize_with_owner(deployer: &signer, initial_owner: address)  // 指定初始所有者

// 权限验证系统
public fun assert_owner(caller: &signer, contract_addr: address) // 断言调用者为所有者
public fun is_owner(caller: &signer, contract_addr: address): bool // 检查是否为所有者
```

**安全机制：**
- 防重复初始化检查：`assert!(!exists<OwnershipInfo>(account_addr))`
- 所有权转移原子性：使用 `borrow_global_mut` 确保状态一致性
- 事件追踪：每次所有权变更都触发 `OwnershipTransferred` 事件

---

## 2. **AccessControl 模组** - 角色权限管理系统 🔐

### 核心数据结构
```move
struct AccessControlInfo has key {
    roles: SmartTable<String, RoleData>,
}

struct RoleData has store {
    members: SmartTable<address, bool>,
    admin_role: String,
}
```

### 架构特点：
- **层级角色系统**：每个角色都有对应的管理员角色，形成权限树
- **SmartTable 优化**：使用 Aptos 的 SmartTable 实现高效的角色-成员映射
- **字符串角色标识**：使用 UTF-8 字符串作为角色唯一标识符

### 权限管理流程：
```move
// 角色检查 - 核心权限验证
public fun has_role(contract_addr: address, role: String, account: address): bool

// 角色授予 - 需要管理员权限
public fun grant_role(admin: &signer, contract_addr: address, role: String, account: address)

// 角色撤销 - 支持管理员撤销和自我放弃
public fun revoke_role(admin: &signer, contract_addr: address, role: String, account: address)
public fun renounce_role(caller: &signer, contract_addr: address, role: String, caller_confirmation: address)
```

**安全机制：**
- **管理员权限验证**：只有角色的管理员才能授予/撤销该角色
- **自我确认机制**：放弃角色需要地址确认，防止误操作
- **默认管理员角色**：`DEFAULT_ADMIN_ROLE` 作为根权限管理所有角色

---

## 3. **CapabilityStore 模组** - 能力委托管理系统 🎯

### 核心数据结构
```move
struct CapabilityStore has key {
    capabilities: SmartTable<String, CapabilityMetadata>,
    delegated_capabilities: SmartTable<String, vector<address>>,
}

struct CapabilityMetadata has store, drop {
    granted_by: address,
    can_delegate: bool,
    delegated_from: vector<address>, // 委托链追踪
}
```

### 架构特点：
- **泛型能力系统**：支持任何具有 `store + drop` 约束的类型作为能力
- **委托链追踪**：完整记录权限传递路径，确保可审计性
- **类型安全保证**：基于 Move 类型系统的编译时安全检查

### 能力管理流程：
```move
// 泛型能力授予
public fun grant_capability<T: store + drop>(
    granter: &signer,
    grantee_addr: address,
    capability: T,
    can_delegate: bool
)

// 能力委托 - 支持权限传递
public fun delegate_capability<T: store + drop>(
    delegator: &signer,
    delegatee_addr: address,
    capability: T
)

// 类型安全检查
public fun has_capability<T>(addr: address): bool
public fun assert_capability<T>(caller: &signer)
```

**独特优势：**
- **Move 语言特有**：充分利用 Move 的资源和能力系统
- **委托控制**：被委托的能力默认不能再次委托，防止权限泛滥
- **类型级别安全**：编译期确保能力类型匹配

---

## 4. **Pausable 模组** - 紧急暂停机制 ⏸️

### 核心数据结构
```move
struct PausableState has key {
    paused: bool,
}
```

### 架构特点：
- **极简设计**：单一布尔值控制整个合约状态
- **修饰符模式**：提供类似 Solidity modifier 的功能函数
- **双向控制**：支持暂停和恢复两个方向的状态切换

### 状态控制机制：
```move
// 状态检查函数
public fun is_paused(contract_addr: address): bool
public fun require_not_paused(contract_addr: address)  // 要求非暂停状态
public fun require_paused(contract_addr: address)      // 要求暂停状态

// 修饰符风格的检查函数
public fun when_not_paused(contract_addr: address)     // 仅在非暂停时执行
public fun when_paused(contract_addr: address)         // 仅在暂停时执行

// 状态切换函数
public fun pause(pauser: &signer, contract_addr: address)
public fun unpause(pauser: &signer, contract_addr: address)
```

**安全特性：**
- **状态一致性**：防止重复暂停或重复恢复
- **事件记录**：每次状态变更都记录 `Paused`/`Unpaused` 事件
- **紧急响应**：专门的紧急暂停函数用于快速响应

---

## 5. **BlockLimiter 模组** - 区块级限流控制系统 🚦

### 核心数据结构
```move
struct BlockLimiterConfig has key {
    max_accesses_per_block_window: u64,    // 区块窗口内最大访问次数
    block_window_size: u64,                // 区块窗口大小
    max_accesses_per_time_window: u64,     // 时间窗口内最大访问次数
    time_window_size: u64,                 // 时间窗口大小（微秒）
    block_cooldown: u64,                   // 区块冷却期
    time_cooldown: u64,                    // 时间冷却期
    admin: address,                        // 管理员地址
    access_records: SmartTable<address, AccessRecord>,  // 访问记录表
}

struct AccessRecord has store, drop {
    last_access_block: u64,     // 最后访问区块
    last_access_time: u64,      // 最后访问时间
    access_count_in_window: u64, // 窗口内访问次数
    window_start_block: u64,    // 窗口起始区块
    window_start_time: u64,     // 窗口起始时间
}
```

### 架构特点：
- **双重限流机制**：同时基于区块高度和时间戳进行限制
- **滑动窗口算法**：动态调整访问窗口，精确控制访问频率
- **个性化记录**：为每个账户维护独立的访问历史

### 限流控制流程：
```move
// 访问权限检查 - 不产生副作用
public fun is_access_allowed(config_addr: address, account_addr: address): bool

// 访问记录更新 - 记录访问行为
public fun record_access(account: &signer, config_addr: address)

// 综合访问控制 - 检查并记录
public fun require_access(account: &signer, config_addr: address)
```

**限流算法：**
1. **冷却期检查**：确保两次访问间隔满足最小冷却时间
2. **窗口重置判断**：检查是否需要开启新的时间/区块窗口
3. **频率限制验证**：在当前窗口内检查访问次数是否超限
4. **访问记录更新**：更新用户的访问历史和窗口状态

---

## 🔗 模组协同设计原则

### 组合使用模式：
```move
// 典型的安全合约结构
public fun secure_operation(caller: &signer, contract_addr: address) {
    // 1. 检查所有权或角色权限
    ownable::only_owner(caller, contract_addr);
    // 或者
    access_control::only_role(caller, contract_addr, admin_role);
    
    // 2. 检查合约未暂停
    pausable::when_not_paused(contract_addr);
    
    // 3. 检查访问频率限制
    block_limiter::require_access(caller, contract_addr);
    
    // 4. 验证特殊能力
    capability_store::assert_capability<SpecialCapability>(caller);
    
    // 5. 执行业务逻辑
    // ... 实际操作代码 ...
}
```

### 模组间依赖关系：
- **Ownable** → **AccessControl**：所有者管理角色系统
- **AccessControl** → **Pausable**：特定角色控制暂停状态
- **CapabilityStore** ↔ **BlockLimiter**：能力委托受频率限制约束
- **所有模组** → **Event System**：统一的事件追踪和审计

---

## 🛡️ 安全设计哲学

### Move 语言优势的充分利用：
1. **资源安全性**：利用 `key` 能力确保全局唯一性
2. **线性类型系统**：防止资源重复使用和悬空引用
3. **编译时验证**：类型安全在编译期得到保证
4. **形式化验证友好**：代码结构支持数学证明

### 统一的错误处理策略：
```move
// 标准化错误码设计
const EUNAUTHORIZED: u64 = 1;      // 权限不足
const EINVALID_INPUT: u64 = 2;     // 输入无效
const EALREADY_EXISTS: u64 = 3;    // 资源已存在
const ENOT_FOUND: u64 = 4;         // 资源未找到
```

### 完整的审计追踪：
- **事件记录**：所有状态变更都通过事件系统记录
- **权限追踪**：记录权限授予、撤销的完整历史
- **访问日志**：详细的访问模式和频率统计

这套架构为 Aptos 生态系统提供了企业级的安全基础设施，开发者可以根据具体需求灵活组合使用这些模组，构建既安全又高效的去中心化应用程序。

---

# 📚 实际使用示范与最佳实践

## 1. 单模组使用示例

### 1.1 Ownable 模组使用示例

```move
module my_project::token_vault {
    use ownable::ownable;
    use aptos_framework::coin;
    
    public fun initialize_vault(owner: &signer) {
        // 初始化所有权管理
        ownable::initialize(owner);
    }
    
    public fun withdraw_emergency_funds<CoinType>(
        caller: &signer, 
        vault_addr: address, 
        amount: u64
    ) {
        // 仅所有者可以提取紧急资金
        ownable::only_owner(caller, vault_addr);
        
        // 执行提取操作
        let coins = coin::withdraw<CoinType>(caller, amount);
        coin::deposit(signer::address_of(caller), coins);
    }
    
    public fun transfer_vault_ownership(
        current_owner: &signer,
        vault_addr: address,
        new_owner: address
    ) {
        ownable::transfer_ownership(current_owner, vault_addr, new_owner);
    }
}
```

### 1.2 AccessControl 模组使用示例

```move
module my_project::token_management {
    use access_control::access_control;
    use std::string;
    
    // 定义角色常量
    const MINTER_ROLE: vector<u8> = b"MINTER_ROLE";
    const BURNER_ROLE: vector<u8> = b"BURNER_ROLE";
    const PAUSER_ROLE: vector<u8> = b"PAUSER_ROLE";
    
    public fun initialize_roles(admin: &signer) {
        // 初始化访问控制，管理员自动获得 DEFAULT_ADMIN_ROLE
        access_control::initialize(admin);
        
        let admin_addr = signer::address_of(admin);
        let minter_role = string::utf8(MINTER_ROLE);
        let burner_role = string::utf8(BURNER_ROLE);
        let pauser_role = string::utf8(PAUSER_ROLE);
        
        // 管理员自己拥有所有角色
        access_control::grant_role(admin, admin_addr, minter_role, admin_addr);
        access_control::grant_role(admin, admin_addr, burner_role, admin_addr);
        access_control::grant_role(admin, admin_addr, pauser_role, admin_addr);
    }
    
    public fun mint_tokens(
        minter: &signer,
        contract_addr: address,
        to: address,
        amount: u64
    ) {
        // 检查铸币权限
        access_control::only_role(minter, contract_addr, string::utf8(MINTER_ROLE));
        
        // 执行铸币逻辑
        // ... 铸币代码 ...
    }
    
    public fun grant_minter_role(
        admin: &signer,
        contract_addr: address,
        new_minter: address
    ) {
        let minter_role = string::utf8(MINTER_ROLE);
        access_control::grant_role(admin, contract_addr, minter_role, new_minter);
    }
}
```

### 1.3 Pausable 模组使用示例

```move
module my_project::trading_contract {
    use pausable::pausable;
    use aptos_framework::coin;
    
    public fun initialize_trading(deployer: &signer) {
        // 初始化暂停功能（默认未暂停）
        pausable::initialize(deployer);
    }
    
    public fun place_order<CoinType>(
        trader: &signer,
        contract_addr: address,
        amount: u64,
        price: u64
    ) {
        // 确保合约未暂停
        pausable::when_not_paused(contract_addr);
        
        // 执行交易逻辑
        // ... 下单代码 ...
    }
    
    public fun emergency_pause(
        emergency_admin: &signer,
        contract_addr: address
    ) {
        // 紧急暂停交易
        pausable::emergency_pause(emergency_admin, contract_addr);
    }
    
    public fun resume_trading(
        admin: &signer,
        contract_addr: address
    ) {
        // 恢复交易
        pausable::emergency_unpause(admin, contract_addr);
    }
}
```

## 2. 多模组组合使用示例

### 2.1 DeFi 借贷协议示例

```move
module defi_protocol::lending_pool {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use block_limiter::block_limiter;
    use std::string;
    use aptos_framework::coin;
    
    // 角色定义
    const LIQUIDATOR_ROLE: vector<u8> = b"LIQUIDATOR_ROLE";
    const ORACLE_ROLE: vector<u8> = b"ORACLE_ROLE";
    const EMERGENCY_ADMIN_ROLE: vector<u8> = b"EMERGENCY_ADMIN_ROLE";
    
    // 初始化完整的安全系统
    public fun initialize_lending_pool(
        deployer: &signer,
        oracle_addr: address,
        liquidator_addr: address
    ) {
        let deployer_addr = signer::address_of(deployer);
        
        // 1. 初始化所有权
        ownable::initialize(deployer);
        
        // 2. 初始化角色控制
        access_control::initialize(deployer);
        
        // 3. 初始化暂停功能
        pausable::initialize(deployer);
        
        // 4. 初始化访问限制（每个区块窗口最多5次操作，窗口大小10个区块）
        block_limiter::initialize(
            deployer,
            5,  // max_accesses_per_block_window
            10, // block_window_size
            3,  // max_accesses_per_time_window
            300000000, // time_window_size (5分钟，微秒)
            2,  // block_cooldown
            60000000   // time_cooldown (1分钟，微秒)
        );
        
        // 5. 分配角色
        let liquidator_role = string::utf8(LIQUIDATOR_ROLE);
        let oracle_role = string::utf8(ORACLE_ROLE);
        let emergency_role = string::utf8(EMERGENCY_ADMIN_ROLE);
        
        access_control::grant_role(deployer, deployer_addr, liquidator_role, liquidator_addr);
        access_control::grant_role(deployer, deployer_addr, oracle_role, oracle_addr);
        access_control::grant_role(deployer, deployer_addr, emergency_role, deployer_addr);
    }
    
    // 存款功能 - 综合安全检查
    public fun deposit<CoinType>(
        user: &signer,
        contract_addr: address,
        amount: u64
    ) {
        // 1. 检查合约未暂停
        pausable::when_not_paused(contract_addr);
        
        // 2. 检查访问频率限制
        block_limiter::require_access(user, contract_addr);
        
        // 3. 执行存款逻辑
        let coins = coin::withdraw<CoinType>(user, amount);
        // ... 存款处理逻辑 ...
        
        // 4. 发放相应的借贷凭证
        // ... 凭证发放逻辑 ...
    }
    
    // 清算功能 - 需要清算者角色
    public fun liquidate_position<CollateralType, DebtType>(
        liquidator: &signer,
        contract_addr: address,
        borrower_addr: address,
        debt_amount: u64
    ) {
        // 1. 检查合约未暂停
        pausable::when_not_paused(contract_addr);
        
        // 2. 检查清算者权限
        access_control::only_role(
            liquidator, 
            contract_addr, 
            string::utf8(LIQUIDATOR_ROLE)
        );
        
        // 3. 检查访问频率限制
        block_limiter::require_access(liquidator, contract_addr);
        
        // 4. 执行清算逻辑
        // ... 清算代码 ...
    }
    
    // 紧急暂停 - 需要紧急管理员权限
    public fun emergency_shutdown(
        emergency_admin: &signer,
        contract_addr: address
    ) {
        access_control::only_role(
            emergency_admin,
            contract_addr,
            string::utf8(EMERGENCY_ADMIN_ROLE)
        );
        
        pausable::emergency_pause(emergency_admin, contract_addr);
    }
    
    // 系统配置更新 - 仅所有者
    public fun update_risk_parameters(
        owner: &signer,
        contract_addr: address,
        new_collateral_ratio: u64,
        new_liquidation_threshold: u64
    ) {
        ownable::only_owner(owner, contract_addr);
        
        // 更新风险参数
        // ... 参数更新代码 ...
    }
}
```

### 2.2 NFT 市场合约示例

```move
module nft_marketplace::marketplace {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use capability_store::capability_store;
    use std::string;
    
    // 定义特殊能力
    struct VIPTraderCapability has key, store, drop {
        tier: u8,
        discount_rate: u64,
    }
    
    struct CuratorCapability has key, store, drop {
        collection_limit: u64,
    }
    
    // 角色定义
    const CURATOR_ROLE: vector<u8> = b"CURATOR_ROLE";
    const MODERATOR_ROLE: vector<u8> = b"MODERATOR_ROLE";
    
    public fun initialize_marketplace(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        
        // 初始化所有安全模组
        ownable::initialize(deployer);
        access_control::initialize(deployer);
        pausable::initialize(deployer);
        capability_store::initialize(deployer);
        
        // 设置角色
        let curator_role = string::utf8(CURATOR_ROLE);
        let moderator_role = string::utf8(MODERATOR_ROLE);
        
        access_control::grant_role(deployer, deployer_addr, curator_role, deployer_addr);
        access_control::grant_role(deployer, deployer_addr, moderator_role, deployer_addr);
    }
    
    // 创建收藏 - 需要策展人角色和能力
    public fun create_collection(
        creator: &signer,
        contract_addr: address,
        collection_name: string::String,
        max_supply: u64
    ) {
        // 1. 检查未暂停
        pausable::when_not_paused(contract_addr);
        
        // 2. 检查策展人角色
        access_control::only_role(creator, contract_addr, string::utf8(CURATOR_ROLE));
        
        // 3. 检查策展人能力
        capability_store::assert_capability<CuratorCapability>(creator);
        
        // 4. 创建收藏
        // ... 收藏创建逻辑 ...
    }
    
    // VIP 交易 - 享受折扣
    public fun vip_purchase(
        buyer: &signer,
        contract_addr: address,
        nft_id: u64,
        listed_price: u64
    ) {
        pausable::when_not_paused(contract_addr);
        
        // 检查 VIP 能力
        capability_store::assert_capability<VIPTraderCapability>(buyer);
        
        // 获取 VIP 折扣信息
        // let (_, _, _) = capability_store::get_capability_metadata<VIPTraderCapability>(
        //     signer::address_of(buyer)
        // );
        
        // 计算折扣价格并执行购买
        // ... VIP 购买逻辑 ...
    }
    
    // 授予 VIP 能力 - 仅所有者
    public fun grant_vip_capability(
        owner: &signer,
        contract_addr: address,
        user_addr: address,
        tier: u8,
        discount_rate: u64
    ) {
        ownable::only_owner(owner, contract_addr);
        
        let vip_capability = VIPTraderCapability {
            tier,
            discount_rate,
        };
        
        capability_store::grant_capability(
            owner,
            user_addr,
            vip_capability,
            false // VIP 能力不可委托
        );
    }
}
```

## 3. 实际业务场景应用

### 3.1 去中心化交易所 (DEX)

```move
module dex::automated_market_maker {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    use block_limiter::block_limiter;
    
    const LIQUIDITY_PROVIDER_ROLE: vector<u8> = b"LIQUIDITY_PROVIDER";
    const PRICE_ORACLE_ROLE: vector<u8> = b"PRICE_ORACLE";
    
    public fun swap_tokens<TokenA, TokenB>(
        trader: &signer,
        contract_addr: address,
        amount_in: u64,
        min_amount_out: u64
    ) {
        // 多层安全检查
        pausable::when_not_paused(contract_addr);
        block_limiter::require_access(trader, contract_addr);
        
        // 执行交易逻辑
        // ... AMM 交易算法 ...
    }
    
    public fun add_liquidity<TokenA, TokenB>(
        provider: &signer,
        contract_addr: address,
        amount_a: u64,
        amount_b: u64
    ) {
        pausable::when_not_paused(contract_addr);
        access_control::only_role(
            provider, 
            contract_addr, 
            string::utf8(LIQUIDITY_PROVIDER_ROLE)
        );
        
        // 添加流动性逻辑
        // ... 流动性添加算法 ...
    }
}
```

### 3.2 游戏道具系统

```move
module game::item_system {
    use ownable::ownable;
    use capability_store::capability_store;
    use pausable::pausable;
    
    struct GameMasterCapability has key, store, drop {
        level: u8,
    }
    
    struct RareItemCapability has key, store, drop {
        item_type: u64,
    }
    
    public fun craft_legendary_item(
        player: &signer,
        contract_addr: address,
        item_recipe: vector<u64>
    ) {
        pausable::when_not_paused(contract_addr);
        
        // 检查是否有游戏管理员能力或稀有物品制作能力
        let has_gm = capability_store::has_capability<GameMasterCapability>(
            signer::address_of(player)
        );
        let has_rare_item = capability_store::has_capability<RareItemCapability>(
            signer::address_of(player)
        );
        
        assert!(has_gm || has_rare_item, 1);
        
        // 制作传说物品
        // ... 物品制作逻辑 ...
    }
}
```

## 4. 最佳实践总结

### 4.1 安全检查顺序建议

```move
public fun secure_function_template(
    caller: &signer,
    contract_addr: address,
    // ... 其他参数
) {
    // 1. 首先检查暂停状态（最基础的安全门）
    pausable::when_not_paused(contract_addr);
    
    // 2. 检查权限（所有权 > 角色权限 > 能力）
    // 选择其一或组合使用：
    // ownable::only_owner(caller, contract_addr);
    // access_control::only_role(caller, contract_addr, role);
    // capability_store::assert_capability<T>(caller);
    
    // 3. 检查访问频率限制
    block_limiter::require_access(caller, contract_addr);
    
    // 4. 执行业务逻辑
    // ... 实际功能代码 ...
}
```

### 4.2 初始化模式

```move
public fun initialize_secure_contract(deployer: &signer) {
    // 1. 基础权限初始化
    ownable::initialize(deployer);
    access_control::initialize(deployer);
    
    // 2. 状态控制初始化
    pausable::initialize(deployer);
    
    // 3. 高级功能初始化
    capability_store::initialize(deployer);
    block_limiter::initialize(deployer, /*参数*/);
    
    // 4. 设置初始角色和权限
    // ... 角色分配代码 ...
}
```

### 4.3 错误处理统一化

```move
// 统一错误码定义
const EUNAUTHORIZED: u64 = 1;
const ECONTRACT_PAUSED: u64 = 2;
const ERATE_LIMITED: u64 = 3;
const EINVALID_CAPABILITY: u64 = 4;
const EINSUFFICIENT_FUNDS: u64 = 5;
```

这些示例展示了如何在实际项目中有效地使用这些安全模组，为开发者提供了具体的参考和最佳实践指导。 