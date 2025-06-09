# OpenZeppelin Move 合约模块

这个项目基于 [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) 的功能，为 Move 语言实现了一套完整的安全合约模块。

## 模块概览

### 1. Ownable (所有权管理)
`ownable::ownable` 模块提供基本的所有权管理功能。

**主要功能：**
- 设置和转移合约所有权
- 放弃所有权
- 所有者权限验证

**核心函数：**
```move
// 初始化所有权
public fun initialize(owner: &signer)
public fun initialize_with_owner(deployer: &signer, initial_owner: address)

// 所有权管理
public fun transfer_ownership(owner: &signer, contract_addr: address, new_owner: address)
public fun renounce_ownership(owner: &signer, contract_addr: address)

// 权限检查
public fun only_owner(caller: &signer, contract_addr: address)
public fun is_owner(caller: &signer, contract_addr: address): bool
```

### 2. AccessControl (访问控制)
`access_control::access_control` 模块实现基于角色的访问控制（RBAC）。

**主要功能：**
- 角色管理（授予、撤销、放弃）
- 角色层次结构（管理员角色）
- 精细化权限控制

**核心函数：**
```move
// 初始化访问控制
public fun initialize(admin: &signer)

// 角色管理
public fun grant_role(admin: &signer, contract_addr: address, role: String, account: address)
public fun revoke_role(admin: &signer, contract_addr: address, role: String, account: address)
public fun renounce_role(caller: &signer, contract_addr: address, role: String, caller_confirmation: address)

// 权限检查
public fun has_role(contract_addr: address, role: String, account: address): bool
public fun only_role(caller: &signer, contract_addr: address, role: String)
```

### 3. CapabilityStore (能力存储)
`capability_store::capability_store` 模块提供安全的能力管理和委托机制。

**主要功能：**
- 能力授予和撤销
- 能力委托
- 能力链追踪

**核心函数：**
```move
// 初始化能力存储
public fun initialize(owner: &signer)

// 能力管理
public fun grant_capability<T: store>(granter: &signer, grantee_addr: address, capability: T, can_delegate: bool)
public fun revoke_capability<T: store>(revoker: &signer, revokee_addr: address)
public fun delegate_capability<T: store>(delegator: &signer, delegatee_addr: address, capability: T)

// 权限检查
public fun has_capability<T>(addr: address): bool
public fun assert_capability<T>(caller: &signer)
```

### 4. Pausable (暂停功能)
`pausable::pausable` 模块提供紧急停止机制。

**主要功能：**
- 暂停和恢复合约
- 暂停状态检查
- 紧急暂停功能

**核心函数：**
```move
// 初始化暂停状态
public fun initialize(account: &signer)

// 暂停控制
public fun pause(pauser: &signer, contract_addr: address)
public fun unpause(pauser: &signer, contract_addr: address)

// 状态检查
public fun is_paused(contract_addr: address): bool
public fun when_not_paused(contract_addr: address)
public fun when_paused(contract_addr: address)
```

### 5. BlockLimiter (区块限制器)
`block_limiter::block_limiter` 模块提供基于区块和时间的访问频率限制。

**主要功能：**
- 区块窗口访问限制
- 时间窗口访问限制
- 冷却期设置
- 访问记录追踪

**核心函数：**
```move
// 初始化限制器
public fun initialize(admin: &signer, max_accesses_per_block_window: u64, block_window_size: u64, ...)

// 访问控制
public fun record_access(caller: &signer, config_addr: address)
public fun require_access(caller: &signer, config_addr: address)
public fun is_access_allowed(config_addr: address, account: address): bool

// 配置管理
public fun update_block_limits(admin: &signer, config_addr: address, ...)
public fun update_time_limits(admin: &signer, config_addr: address, ...)
```

## 使用示例

### 基本设置

```move
module my_contract::my_token {
    use ownable::ownable;
    use access_control::access_control;
    use pausable::pausable;
    
    const MINTER_ROLE: vector<u8> = b"MINTER_ROLE";
    
    public fun initialize(deployer: &signer, owner: address) {
        // 初始化所有模块
        ownable::initialize_with_owner(deployer, owner);
        access_control::initialize(deployer);
        pausable::initialize(deployer);
        
        // 设置角色
        let minter_role = string::utf8(MINTER_ROLE);
        access_control::grant_role(deployer, deployer_addr, minter_role, owner);
    }
    
    public fun mint(minter: &signer, contract_addr: address, amount: u64) {
        // 检查暂停状态
        pausable::when_not_paused(contract_addr);
        
        // 检查铸币权限
        access_control::only_role(minter, contract_addr, string::utf8(MINTER_ROLE));
        
        // 执行铸币逻辑...
    }
    
    public fun pause(owner: &signer, contract_addr: address) {
        ownable::only_owner(owner, contract_addr);
        pausable::pause(owner, contract_addr);
    }
}
```

### 组合使用多个模块

参见 `example_contract.move` 文件，展示了如何将所有模块组合使用：

```move
// 完整的安全检查
public fun mint(minter: &signer, contract_addr: address, to: address, amount: u64) {
    // 1. 检查暂停状态
    pausable::when_not_paused(contract_addr);
    
    // 2. 检查访问频率限制
    block_limiter::require_access(minter, contract_addr);
    
    // 3. 检查角色权限
    access_control::only_role(minter, contract_addr, string::utf8(MINTER_ROLE));
    
    // 4. 执行业务逻辑
    // ...
}
```

## 安全特性

### 1. 多层安全防护
- **所有权控制**：确保只有授权的所有者可以执行关键操作
- **角色管理**：细粒度的权限控制
- **暂停机制**：紧急情况下快速停止合约
- **频率限制**：防止滥用和DoS攻击

### 2. 事件记录
所有模块都会发出详细的事件，便于监控和审计：
- 所有权转移事件
- 角色授予/撤销事件
- 暂停/恢复事件
- 访问限制事件

### 3. 错误处理
完善的错误码系统，便于调试和错误处理：
```move
const EUNAUTHORIZED: u64 = 1;
const EINVALID_OWNER: u64 = 2;
const EALREADY_INITIALIZED: u64 = 3;
// ...
```

## 部署和测试

### 1. 编译项目
```bash
cd move
aptos move compile
```

### 2. 运行测试
```bash
aptos move test
```

### 3. 部署合约
```bash
aptos move publish --profile <your-profile>
```

## 最佳实践

### 1. 初始化顺序
确保按正确顺序初始化所有模块：
1. 先初始化基础模块（Ownable, AccessControl）
2. 再初始化功能模块（Pausable, BlockLimiter）
3. 最后设置角色和权限

### 2. 权限分离
- 使用不同的角色进行权限分离
- 避免给单一账户过多权限
- 定期审核和更新权限

### 3. 紧急响应
- 为关键操作设置暂停机制
- 配置合理的访问频率限制
- 监控异常事件和模式

### 4. 测试覆盖
- 测试所有权限组合
- 测试边界条件
- 测试紧急情况处理

## 注意事项

1. **初始化**: 所有模块都需要在使用前进行初始化
2. **权限检查**: 确保在执行敏感操作前进行适当的权限检查
3. **事件监听**: 监听相关事件以便及时响应安全问题
4. **定期审计**: 定期检查角色分配和访问模式

## 许可证

本项目基于 MIT 许可证开源。 