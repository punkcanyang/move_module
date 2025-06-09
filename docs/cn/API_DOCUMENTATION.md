# 🔧 Move 安全模组 API 文档

本文档提供了所有五个 Move 安全模组的完整 API 参考和使用示例。

## 📚 目录

1. [Ownable 模组 API](#1-ownable-模组-api)
2. [AccessControl 模组 API](#2-accesscontrol-模组-api)
3. [Pausable 模组 API](#3-pausable-模组-api)
4. [CapabilityStore 模组 API](#4-capabilitystore-模组-api)
5. [BlockLimiter 模组 API](#5-blocklimiter-模组-api)
6. [错误码参考](#6-错误码参考)
7. [最佳实践](#7-最佳实践)

---

## 1. Ownable 模组 API

### 模组导入
```move
use ownable::ownable;
```

### 数据结构

#### OwnershipInfo
```move
struct OwnershipInfo has key {
    owner: address,
}
```
**说明**：存储合约所有权信息的资源

### 公共函数

#### 1.1 initialize
```move
public fun initialize(account: &signer)
```
**功能**：初始化所有权，调用者成为所有者  
**参数**：
- `account: &signer` - 将成为所有者的账户  

**异常**：
- `EALREADY_INITIALIZED (3)` - 所有权已初始化

**示例**：
```move
public fun setup_contract(deployer: &signer) {
    ownable::initialize(deployer);
}
```

#### 1.2 initialize_with_owner
```move
public fun initialize_with_owner(deployer: &signer, initial_owner: address)
```
**功能**：初始化所有权并指定特定的初始所有者  
**参数**：
- `deployer: &signer` - 部署账户
- `initial_owner: address` - 初始所有者地址

**异常**：
- `EALREADY_INITIALIZED (3)` - 所有权已初始化
- `EINVALID_OWNER (2)` - 初始所有者为零地址

**示例**：
```move
public fun setup_with_admin(deployer: &signer, admin: address) {
    ownable::initialize_with_owner(deployer, admin);
}
```

#### 1.3 owner
```move
public fun owner(contract_addr: address): address
```
**功能**：获取当前所有者地址  
**参数**：
- `contract_addr: address` - 合约地址

**返回值**：`address` - 当前所有者地址

**示例**：
```move
let current_owner = ownable::owner(@0x123);
```

#### 1.4 is_owner
```move
public fun is_owner(caller: &signer, contract_addr: address): bool
```
**功能**：检查调用者是否为所有者  
**参数**：
- `caller: &signer` - 调用者账户
- `contract_addr: address` - 合约地址

**返回值**：`bool` - 是否为所有者

**示例**：
```move
if (ownable::is_owner(caller, contract_addr)) {
    // 执行所有者操作
};
```

#### 1.5 assert_owner
```move
public fun assert_owner(caller: &signer, contract_addr: address)
```
**功能**：断言调用者为所有者，否则终止执行  
**参数**：
- `caller: &signer` - 调用者账户
- `contract_addr: address` - 合约地址

**异常**：
- `EUNAUTHORIZED (1)` - 调用者非所有者

**示例**：
```move
public fun admin_function(caller: &signer, contract_addr: address) {
    ownable::assert_owner(caller, contract_addr);
    // 执行管理员操作
}
```

#### 1.6 transfer_ownership
```move
public fun transfer_ownership(owner: &signer, contract_addr: address, new_owner: address)
```
**功能**：转移所有权给新所有者  
**参数**：
- `owner: &signer` - 当前所有者
- `contract_addr: address` - 合约地址
- `new_owner: address` - 新所有者地址

**异常**：
- `EUNAUTHORIZED (1)` - 调用者非所有者
- `EINVALID_OWNER (2)` - 新所有者为零地址

**事件**：`OwnershipTransferred`

**示例**：
```move
public fun handover_control(current_owner: &signer, contract_addr: address, successor: address) {
    ownable::transfer_ownership(current_owner, contract_addr, successor);
}
```

#### 1.7 renounce_ownership
```move
public fun renounce_ownership(owner: &signer, contract_addr: address)
```
**功能**：放弃所有权（设置为零地址）  
**参数**：
- `owner: &signer` - 当前所有者
- `contract_addr: address` - 合约地址

**异常**：
- `EUNAUTHORIZED (1)` - 调用者非所有者

**事件**：`OwnershipTransferred`

**示例**：
```move
public fun make_ownerless(owner: &signer, contract_addr: address) {
    ownable::renounce_ownership(owner, contract_addr);
}
```

#### 1.8 only_owner
```move
public fun only_owner(caller: &signer, contract_addr: address)
```
**功能**：修饰符风格的所有者检查函数  
**参数**：
- `caller: &signer` - 调用者账户
- `contract_addr: address` - 合约地址

**异常**：
- `EUNAUTHORIZED (1)` - 调用者非所有者

**示例**：
```move
public fun restricted_function(caller: &signer, contract_addr: address) {
    ownable::only_owner(caller, contract_addr);
    // 仅所有者可执行的代码
}
```

### 事件

#### OwnershipTransferred
```move
struct OwnershipTransferred has drop, store {
    previous_owner: address,
    new_owner: address,
}
```
**触发时机**：所有权转移或放弃时  
**字段**：
- `previous_owner: address` - 前任所有者
- `new_owner: address` - 新所有者（放弃时为 @0x0）

---

## 2. AccessControl 模组 API

### 模组导入
```move
use access_control::access_control;
use std::string;
```

### 数据结构

#### AccessControlInfo
```move
struct AccessControlInfo has key {
    roles: SmartTable<String, RoleData>,
}
```

#### RoleData
```move
struct RoleData has store {
    members: SmartTable<address, bool>,
    admin_role: String,
}
```

### 常量

#### DEFAULT_ADMIN_ROLE
```move
const DEFAULT_ADMIN_ROLE: vector<u8> = b"DEFAULT_ADMIN_ROLE";
```

### 公共函数

#### 2.1 initialize
```move
public fun initialize(deployer: &signer)
```
**功能**：初始化访问控制系统，部署者获得默认管理员角色  
**参数**：
- `deployer: &signer` - 部署者账户

**异常**：
- `EALREADY_INITIALIZED (3)` - 访问控制已初始化

**示例**：
```move
public fun setup_access_control(admin: &signer) {
    access_control::initialize(admin);
}
```

#### 2.2 has_role
```move
public fun has_role(contract_addr: address, role: String, account: address): bool
```
**功能**：检查账户是否拥有指定角色  
**参数**：
- `contract_addr: address` - 合约地址
- `role: String` - 角色名称
- `account: address` - 账户地址

**返回值**：`bool` - 是否拥有角色

**示例**：
```move
let minter_role = string::utf8(b"MINTER_ROLE");
if (access_control::has_role(contract_addr, minter_role, user_addr)) {
    // 用户拥有铸币权限
};
```

#### 2.3 grant_role
```move
public fun grant_role(admin: &signer, contract_addr: address, role: String, account: address)
```
**功能**：授予账户指定角色  
**参数**：
- `admin: &signer` - 管理员账户
- `contract_addr: address` - 合约地址
- `role: String` - 角色名称
- `account: address` - 目标账户地址

**异常**：
- `EUNAUTHORIZED (1)` - 调用者无权限授予此角色

**事件**：`RoleGranted`

**示例**：
```move
public fun add_minter(admin: &signer, contract_addr: address, new_minter: address) {
    let minter_role = string::utf8(b"MINTER_ROLE");
    access_control::grant_role(admin, contract_addr, minter_role, new_minter);
}
```

#### 2.4 revoke_role
```move
public fun revoke_role(admin: &signer, contract_addr: address, role: String, account: address)
```
**功能**：撤销账户的指定角色  
**参数**：
- `admin: &signer` - 管理员账户
- `contract_addr: address` - 合约地址
- `role: String` - 角色名称
- `account: address` - 目标账户地址

**异常**：
- `EUNAUTHORIZED (1)` - 调用者无权限撤销此角色

**事件**：`RoleRevoked`

**示例**：
```move
public fun remove_minter(admin: &signer, contract_addr: address, minter: address) {
    let minter_role = string::utf8(b"MINTER_ROLE");
    access_control::revoke_role(admin, contract_addr, minter_role, minter);
}
```

#### 2.5 renounce_role
```move
public fun renounce_role(caller: &signer, contract_addr: address, role: String, caller_confirmation: address)
```
**功能**：放弃自己的角色  
**参数**：
- `caller: &signer` - 调用者账户
- `contract_addr: address` - 合约地址
- `role: String` - 角色名称
- `caller_confirmation: address` - 调用者地址确认

**异常**：
- `EBAD_CONFIRMATION (4)` - 确认地址不匹配

**事件**：`RoleRevoked`

**示例**：
```move
public fun give_up_role(caller: &signer, contract_addr: address) {
    let role = string::utf8(b"MINTER_ROLE");
    let caller_addr = signer::address_of(caller);
    access_control::renounce_role(caller, contract_addr, role, caller_addr);
}
```

#### 2.6 get_role_admin
```move
public fun get_role_admin(contract_addr: address, role: String): String
```
**功能**：获取指定角色的管理员角色  
**参数**：
- `contract_addr: address` - 合约地址
- `role: String` - 角色名称

**返回值**：`String` - 管理员角色名称

**示例**：
```move
let admin_role = access_control::get_role_admin(contract_addr, minter_role);
```

#### 2.7 only_role
```move
public fun only_role(caller: &signer, contract_addr: address, role: String)
```
**功能**：修饰符风格的角色检查函数  
**参数**：
- `caller: &signer` - 调用者账户
- `contract_addr: address` - 合约地址
- `role: String` - 角色名称

**异常**：
- `EUNAUTHORIZED (1)` - 调用者无此角色

**示例**：
```move
public fun mint_tokens(caller: &signer, contract_addr: address) {
    let minter_role = string::utf8(b"MINTER_ROLE");
    access_control::only_role(caller, contract_addr, minter_role);
    // 执行铸币操作
}
```

#### 2.8 default_admin_role
```move
public fun default_admin_role(): String
```
**功能**：获取默认管理员角色字符串  
**返回值**：`String` - 默认管理员角色

**示例**：
```move
let admin_role = access_control::default_admin_role();
```

### 事件

#### RoleGranted
```move
struct RoleGranted has drop, store {
    role: String,
    account: address,
    sender: address,
}
```

#### RoleRevoked
```move
struct RoleRevoked has drop, store {
    role: String,
    account: address,
    sender: address,
}
```

---

## 3. Pausable 模组 API

### 模组导入
```move
use pausable::pausable;
```

### 数据结构

#### PausableState
```move
struct PausableState has key {
    paused: bool,
}
```

### 公共函数

#### 3.1 initialize
```move
public fun initialize(account: &signer)
```
**功能**：初始化暂停功能（默认未暂停）  
**参数**：
- `account: &signer` - 初始化账户

**异常**：
- `EALREADY_INITIALIZED (3)` - 暂停功能已初始化

**示例**：
```move
public fun setup_pausable(deployer: &signer) {
    pausable::initialize(deployer);
}
```

#### 3.2 is_paused
```move
public fun is_paused(contract_addr: address): bool
```
**功能**：检查合约是否处于暂停状态  
**参数**：
- `contract_addr: address` - 合约地址

**返回值**：`bool` - 是否暂停

**示例**：
```move
if (!pausable::is_paused(contract_addr)) {
    // 合约未暂停，可以执行操作
};
```

#### 3.3 require_not_paused
```move
public fun require_not_paused(contract_addr: address)
```
**功能**：要求合约未暂停，否则终止执行  
**参数**：
- `contract_addr: address` - 合约地址

**异常**：
- `EENFORCED_PAUSE (1)` - 合约已暂停

**示例**：
```move
public fun normal_operation(contract_addr: address) {
    pausable::require_not_paused(contract_addr);
    // 正常业务逻辑
}
```

#### 3.4 require_paused
```move
public fun require_paused(contract_addr: address)
```
**功能**：要求合约已暂停，否则终止执行  
**参数**：
- `contract_addr: address` - 合约地址

**异常**：
- `EEXPECTED_PAUSE (2)` - 合约未暂停

**示例**：
```move
public fun emergency_operation(contract_addr: address) {
    pausable::require_paused(contract_addr);
    // 仅在暂停时可执行的操作
}
```

#### 3.5 pause
```move
public fun pause(pauser: &signer, contract_addr: address)
```
**功能**：暂停合约  
**参数**：
- `pauser: &signer` - 暂停操作者
- `contract_addr: address` - 合约地址

**异常**：
- `EENFORCED_PAUSE (1)` - 合约已暂停

**事件**：`Paused`

**示例**：
```move
public fun emergency_pause(admin: &signer, contract_addr: address) {
    pausable::pause(admin, contract_addr);
}
```

#### 3.6 unpause
```move
public fun unpause(pauser: &signer, contract_addr: address)
```
**功能**：恢复合约运行  
**参数**：
- `pauser: &signer` - 恢复操作者
- `contract_addr: address` - 合约地址

**异常**：
- `EEXPECTED_PAUSE (2)` - 合约未暂停

**事件**：`Unpaused`

**示例**：
```move
public fun resume_operations(admin: &signer, contract_addr: address) {
    pausable::unpause(admin, contract_addr);
}
```

#### 3.7 when_not_paused
```move
public fun when_not_paused(contract_addr: address)
```
**功能**：修饰符风格的非暂停检查  
**参数**：
- `contract_addr: address` - 合约地址

**异常**：
- `EENFORCED_PAUSE (1)` - 合约已暂停

**示例**：
```move
public fun regular_function(contract_addr: address) {
    pausable::when_not_paused(contract_addr);
    // 业务逻辑
}
```

#### 3.8 when_paused
```move
public fun when_paused(contract_addr: address)
```
**功能**：修饰符风格的暂停检查  
**参数**：
- `contract_addr: address` - 合约地址

**异常**：
- `EEXPECTED_PAUSE (2)` - 合约未暂停

**示例**：
```move
public fun emergency_function(contract_addr: address) {
    pausable::when_paused(contract_addr);
    // 紧急操作逻辑
}
```

### 事件

#### Paused
```move
struct Paused has drop, store {
    account: address,
}
```

#### Unpaused
```move
struct Unpaused has drop, store {
    account: address,
}
```

---

## 4. CapabilityStore 模组 API

### 模组导入
```move
use capability_store::capability_store;
```

### 数据结构

#### CapabilityStore
```move
struct CapabilityStore has key {
    capabilities: SmartTable<String, CapabilityMetadata>,
    delegated_capabilities: SmartTable<String, vector<address>>,
}
```

#### CapabilityMetadata
```move
struct CapabilityMetadata has store, drop {
    granted_by: address,
    can_delegate: bool,
    delegated_from: vector<address>,
}
```

### 公共函数

#### 4.1 initialize
```move
public fun initialize(account: &signer)
```
**功能**：初始化能力存储  
**参数**：
- `account: &signer` - 初始化账户

**异常**：
- `EALREADY_INITIALIZED (3)` - 能力存储已初始化

**示例**：
```move
public fun setup_capabilities(user: &signer) {
    capability_store::initialize(user);
}
```

#### 4.2 grant_capability
```move
public fun grant_capability<T: store + drop>(
    granter: &signer,
    grantee_addr: address,
    capability: T,
    can_delegate: bool
)
```
**功能**：授予能力给指定账户  
**参数**：
- `granter: &signer` - 授予者
- `grantee_addr: address` - 接收者地址
- `capability: T` - 能力实例
- `can_delegate: bool` - 是否可委托

**异常**：
- `ECAPABILITY_NOT_FOUND (2)` - 接收者未初始化能力存储

**事件**：`CapabilityGranted`

**示例**：
```move
struct AdminCapability has store, drop {}

public fun grant_admin_rights(owner: &signer, new_admin: address) {
    let admin_cap = AdminCapability {};
    capability_store::grant_capability(owner, new_admin, admin_cap, true);
}
```

#### 4.3 revoke_capability
```move
public fun revoke_capability<T: store + drop>(
    revoker: &signer,
    revokee_addr: address
)
```
**功能**：撤销指定账户的能力  
**参数**：
- `revoker: &signer` - 撤销者
- `revokee_addr: address` - 被撤销者地址

**异常**：
- `EUNAUTHORIZED (1)` - 无权限撤销
- `ECAPABILITY_NOT_FOUND (2)` - 能力不存在

**事件**：`CapabilityRevoked`

**示例**：
```move
public fun revoke_admin_rights(owner: &signer, admin_addr: address) {
    capability_store::revoke_capability<AdminCapability>(owner, admin_addr);
}
```

#### 4.4 delegate_capability
```move
public fun delegate_capability<T: store + drop>(
    delegator: &signer,
    delegatee_addr: address,
    capability: T
)
```
**功能**：委托能力给其他账户  
**参数**：
- `delegator: &signer` - 委托者
- `delegatee_addr: address` - 被委托者地址
- `capability: T` - 能力实例

**异常**：
- `EUNAUTHORIZED (1)` - 无委托权限
- `ECAPABILITY_NOT_FOUND (2)` - 能力不存在

**事件**：`CapabilityDelegated`

**示例**：
```move
public fun delegate_admin_to_deputy(admin: &signer, deputy_addr: address) {
    let admin_cap = AdminCapability {};
    capability_store::delegate_capability(admin, deputy_addr, admin_cap);
}
```

#### 4.5 has_capability
```move
public fun has_capability<T>(addr: address): bool
```
**功能**：检查账户是否拥有指定类型的能力  
**参数**：
- `addr: address` - 账户地址

**返回值**：`bool` - 是否拥有能力

**示例**：
```move
if (capability_store::has_capability<AdminCapability>(user_addr)) {
    // 用户拥有管理员能力
};
```

#### 4.6 assert_capability
```move
public fun assert_capability<T>(caller: &signer)
```
**功能**：断言调用者拥有指定能力  
**参数**：
- `caller: &signer` - 调用者

**异常**：
- `EUNAUTHORIZED (1)` - 无此能力

**示例**：
```move
public fun admin_function(caller: &signer) {
    capability_store::assert_capability<AdminCapability>(caller);
    // 执行管理员操作
}
```

#### 4.7 get_capability_metadata
```move
public fun get_capability_metadata<T>(addr: address): (address, bool, vector<address>)
```
**功能**：获取能力的元数据信息  
**参数**：
- `addr: address` - 账户地址

**返回值**：
- `address` - 授予者地址
- `bool` - 是否可委托
- `vector<address>` - 委托链

**异常**：
- `ECAPABILITY_NOT_FOUND (2)` - 能力不存在

**示例**：
```move
let (granter, can_delegate, chain) = capability_store::get_capability_metadata<AdminCapability>(user_addr);
```

### 事件

#### CapabilityGranted
```move
struct CapabilityGranted has drop, store {
    capability_type: String,
    grantee: address,
    granter: address,
    can_delegate: bool,
}
```

#### CapabilityRevoked
```move
struct CapabilityRevoked has drop, store {
    capability_type: String,
    revokee: address,
    revoker: address,
}
```

#### CapabilityDelegated
```move
struct CapabilityDelegated has drop, store {
    capability_type: String,
    delegator: address,
    delegatee: address,
}
```

---

## 5. BlockLimiter 模组 API

### 模组导入
```move
use block_limiter::block_limiter;
```

### 数据结构

#### BlockLimiterConfig
```move
struct BlockLimiterConfig has key {
    max_accesses_per_block_window: u64,
    block_window_size: u64,
    max_accesses_per_time_window: u64,
    time_window_size: u64,
    block_cooldown: u64,
    time_cooldown: u64,
    admin: address,
    access_records: SmartTable<address, AccessRecord>,
}
```

#### AccessRecord
```move
struct AccessRecord has store, drop {
    last_access_block: u64,
    last_access_time: u64,
    access_count_in_window: u64,
    window_start_block: u64,
    window_start_time: u64,
}
```

### 公共函数

#### 5.1 initialize
```move
public fun initialize(
    admin: &signer,
    max_accesses_per_block_window: u64,
    block_window_size: u64,
    max_accesses_per_time_window: u64,
    time_window_size: u64,
    block_cooldown: u64,
    time_cooldown: u64
)
```
**功能**：初始化区块限制器  
**参数**：
- `admin: &signer` - 管理员账户
- `max_accesses_per_block_window: u64` - 区块窗口内最大访问次数
- `block_window_size: u64` - 区块窗口大小
- `max_accesses_per_time_window: u64` - 时间窗口内最大访问次数
- `time_window_size: u64` - 时间窗口大小（微秒）
- `block_cooldown: u64` - 区块冷却期
- `time_cooldown: u64` - 时间冷却期（微秒）

**异常**：
- `EALREADY_INITIALIZED (3)` - 限制器已初始化

**事件**：`ConfigUpdated`

**示例**：
```move
public fun setup_rate_limiting(admin: &signer) {
    block_limiter::initialize(
        admin,
        5,         // 每10个区块最多5次访问
        10,        // 区块窗口大小
        3,         // 每5分钟最多3次访问
        300000000, // 5分钟（微秒）
        2,         // 2个区块冷却期
        60000000   // 1分钟冷却期
    );
}
```

#### 5.2 is_access_allowed
```move
public fun is_access_allowed(config_addr: address, account_addr: address): bool
```
**功能**：检查是否允许访问（不记录）  
**参数**：
- `config_addr: address` - 配置地址
- `account_addr: address` - 账户地址

**返回值**：`bool` - 是否允许访问

**示例**：
```move
if (block_limiter::is_access_allowed(config_addr, user_addr)) {
    // 可以执行操作
};
```

#### 5.3 record_access
```move
public fun record_access(account: &signer, config_addr: address)
```
**功能**：记录访问（更新限制状态）  
**参数**：
- `account: &signer` - 访问账户
- `config_addr: address` - 配置地址

**异常**：
- `EACCESS_DENIED (1)` - 配置不存在

**事件**：`AccessRecorded`

**示例**：
```move
public fun track_user_access(user: &signer, config_addr: address) {
    block_limiter::record_access(user, config_addr);
}
```

#### 5.4 require_access
```move
public fun require_access(account: &signer, config_addr: address)
```
**功能**：要求访问权限（检查并记录）  
**参数**：
- `account: &signer` - 访问账户
- `config_addr: address` - 配置地址

**异常**：
- `ERATE_LIMITED (2)` - 访问被限制

**示例**：
```move
public fun limited_operation(user: &signer, config_addr: address) {
    block_limiter::require_access(user, config_addr);
    // 执行受限操作
}
```

#### 5.5 check_access
```move
public fun check_access(config_addr: address, account_addr: address): bool
```
**功能**：检查访问状态（只读）  
**参数**：
- `config_addr: address` - 配置地址
- `account_addr: address` - 账户地址

**返回值**：`bool` - 访问状态

**示例**：
```move
let can_access = block_limiter::check_access(config_addr, user_addr);
```

#### 5.6 get_access_record
```move
public fun get_access_record(config_addr: address, account_addr: address): (u64, u64, u64, u64, u64)
```
**功能**：获取账户的访问记录  
**参数**：
- `config_addr: address` - 配置地址
- `account_addr: address` - 账户地址

**返回值**：
- `u64` - 最后访问区块
- `u64` - 最后访问时间
- `u64` - 窗口内访问次数
- `u64` - 窗口起始区块
- `u64` - 窗口起始时间

**示例**：
```move
let (last_block, last_time, count, window_block, window_time) = 
    block_limiter::get_access_record(config_addr, user_addr);
```

#### 5.7 update_block_limits
```move
public fun update_block_limits(
    admin: &signer,
    config_addr: address,
    max_accesses_per_block_window: u64,
    block_window_size: u64,
    block_cooldown: u64
)
```
**功能**：更新区块限制参数（仅管理员）  
**参数**：
- `admin: &signer` - 管理员账户
- `config_addr: address` - 配置地址
- `max_accesses_per_block_window: u64` - 新的区块窗口访问限制
- `block_window_size: u64` - 新的区块窗口大小
- `block_cooldown: u64` - 新的区块冷却期

**异常**：
- `EUNAUTHORIZED (4)` - 非管理员调用

**示例**：
```move
public fun adjust_block_limits(admin: &signer, config_addr: address) {
    block_limiter::update_block_limits(admin, config_addr, 10, 20, 3);
}
```

#### 5.8 update_time_limits
```move
public fun update_time_limits(
    admin: &signer,
    config_addr: address,
    max_accesses_per_time_window: u64,
    time_window_size: u64,
    time_cooldown: u64
)
```
**功能**：更新时间限制参数（仅管理员）  
**参数**：
- `admin: &signer` - 管理员账户
- `config_addr: address` - 配置地址
- `max_accesses_per_time_window: u64` - 新的时间窗口访问限制
- `time_window_size: u64` - 新的时间窗口大小
- `time_cooldown: u64` - 新的时间冷却期

**异常**：
- `EUNAUTHORIZED (4)` - 非管理员调用

**示例**：
```move
public fun adjust_time_limits(admin: &signer, config_addr: address) {
    block_limiter::update_time_limits(admin, config_addr, 5, 600000000, 120000000);
}
```

### 事件

#### AccessRecorded
```move
struct AccessRecorded has drop, store {
    account: address,
    block_height: u64,
    timestamp: u64,
}
```

#### AccessDenied
```move
struct AccessDenied has drop, store {
    account: address,
    reason: u8, // 1: block limit, 2: time limit, 3: cooldown
}
```

#### ConfigUpdated
```move
struct ConfigUpdated has drop, store {
    admin: address,
    max_accesses_per_block_window: u64,
    block_window_size: u64,
    max_accesses_per_time_window: u64,
    time_window_size: u64,
}
```

---

## 6. 错误码参考

### 通用错误码
| 错误码 | 常量名 | 描述 |
|--------|--------|------|
| 1 | `EUNAUTHORIZED` | 权限不足 |
| 2 | `EINVALID_OWNER/EROLE_NOT_FOUND` | 无效所有者/角色未找到 |
| 3 | `EALREADY_INITIALIZED` | 已初始化 |
| 4 | `EBAD_CONFIRMATION/EUNAUTHORIZED` | 确认错误/未授权 |
| 5 | `EINVALID_CONFIG` | 配置无效 |

### 模组特定错误码

#### Ownable
- `EUNAUTHORIZED (1)` - 调用者非所有者
- `EINVALID_OWNER (2)` - 所有者地址无效
- `EALREADY_INITIALIZED (3)` - 所有权已初始化

#### AccessControl
- `EUNAUTHORIZED (1)` - 权限不足
- `EROLE_NOT_FOUND (2)` - 角色不存在
- `EALREADY_INITIALIZED (3)` - 访问控制已初始化
- `EBAD_CONFIRMATION (4)` - 地址确认错误

#### Pausable
- `EENFORCED_PAUSE (1)` - 合约已暂停
- `EEXPECTED_PAUSE (2)` - 期望合约暂停
- `EALREADY_INITIALIZED (3)` - 暂停功能已初始化

#### CapabilityStore
- `EUNAUTHORIZED (1)` - 权限不足
- `ECAPABILITY_NOT_FOUND (2)` - 能力不存在
- `EALREADY_INITIALIZED (3)` - 能力存储已初始化
- `EINVALID_DELEGATION (4)` - 委托无效

#### BlockLimiter
- `EACCESS_DENIED (1)` - 访问被拒绝
- `ERATE_LIMITED (2)` - 访问频率受限
- `EALREADY_INITIALIZED (3)` - 限制器已初始化
- `EUNAUTHORIZED (4)` - 权限不足
- `EINVALID_CONFIG (5)` - 配置无效

---

## 7. 最佳实践

### 7.1 模组组合使用

```move
// 推荐的安全检查顺序
public fun secure_operation(caller: &signer, contract_addr: address) {
    // 1. 基础状态检查
    pausable::when_not_paused(contract_addr);
    
    // 2. 权限验证（选择适当的方式）
    ownable::only_owner(caller, contract_addr);
    // 或
    access_control::only_role(caller, contract_addr, role);
    // 或
    capability_store::assert_capability<T>(caller);
    
    // 3. 频率限制
    block_limiter::require_access(caller, contract_addr);
    
    // 4. 执行业务逻辑
    // ...
}
```

### 7.2 初始化模式

```move
public fun initialize_secure_contract(deployer: &signer) {
    // 基础安全模组
    ownable::initialize(deployer);
    access_control::initialize(deployer);
    pausable::initialize(deployer);
    
    // 高级功能模组
    capability_store::initialize(deployer);
    block_limiter::initialize(deployer, /* 参数 */);
    
    // 设置初始权限
    setup_initial_roles(deployer);
}
```

### 7.3 错误处理

```move
// 统一错误处理
public fun safe_operation(caller: &signer, contract_addr: address) {
    // 使用 assert! 进行前置条件检查
    assert!(some_condition(), error::invalid_state(ERROR_CODE));
    
    // 使用模组提供的检查函数
    ownable::assert_owner(caller, contract_addr);
    
    // 业务逻辑
}
```

### 7.4 事件记录

```move
// 记录关键操作
public fun important_operation(caller: &signer) {
    // 执行操作
    // ...
    
    // 发出事件
    event::emit(OperationCompleted {
        operator: signer::address_of(caller),
        timestamp: timestamp::now_microseconds(),
        operation_id: generate_id(),
    });
}
```

这份 API 文档提供了完整的函数签名、参数说明、返回值、异常情况和使用示例，帮助开发者快速上手和正确使用这些安全模组。 