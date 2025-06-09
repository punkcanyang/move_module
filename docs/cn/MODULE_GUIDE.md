# 🛡️ OpenZeppelin Move 安全模组套件

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Move](https://img.shields.io/badge/Move-Language-blue)](https://github.com/move-language/move)
[![Aptos](https://img.shields.io/badge/Aptos-Compatible-green)](https://aptos.dev/)

这个项目为 Move 语言实现了一套完整的安全合约模组，灵感来源于 [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) 的成熟设计理念，为 Aptos 生态系统提供企业级的安全基础设施。

## 🚀 快速开始

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd move_module

# 检查 Move 环境
aptos move test
```

### 基础使用

```move
module my_app::secure_contract {
    use ownable::ownable;
    use pausable::pausable;
    
    public fun initialize(deployer: &signer) {
        ownable::initialize(deployer);
        pausable::initialize(deployer);
    }
    
    public fun secure_function(caller: &signer, contract_addr: address) {
        pausable::when_not_paused(contract_addr);
        ownable::only_owner(caller, contract_addr);
        // 您的业务逻辑
    }
}
```

## 📦 核心模组

### 1. 🏛️ Ownable (所有权管理)
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

### 2. 🔐 AccessControl (访问控制)
基于角色的访问控制（RBAC）系统，提供细粒度权限管理。

**特性：** 层级角色、管理员权限、动态角色分配

### 3. 🎯 CapabilityStore (能力管理)
Move 特有的能力管理系统，支持安全的权限委托。

**特性：** 泛型能力、委托链追踪、类型安全验证

### 4. ⏸️ Pausable (暂停机制)
紧急停止机制，为合约提供安全开关。

**特性：** 紧急暂停、状态切换、修饰符模式

### 5. 🚦 BlockLimiter (频率限制)
基于区块和时间的访问频率控制系统。

**特性：** 双重限流、滑动窗口、冷却期控制

## 💡 使用场景

| 应用类型 | 推荐模组组合 | 示例场景 |
|----------|-------------|----------|
| **DeFi 协议** | Ownable + AccessControl + Pausable + BlockLimiter | 借贷平台、DEX、流动性挖矿 |
| **NFT 市场** | AccessControl + CapabilityStore + Pausable | 数字藏品、艺术品交易 |
| **游戏应用** | CapabilityStore + AccessControl + BlockLimiter | 道具系统、公会管理 |
| **DAO 治理** | AccessControl + Ownable + Pausable | 投票系统、资金管理 |

## 🛡️ 安全特性

### 多层防护体系
```
┌─────────────────┐
│   业务逻辑层     │
├─────────────────┤
│   频率限制层     │ ← BlockLimiter
├─────────────────┤
│   权限控制层     │ ← AccessControl / CapabilityStore
├─────────────────┤
│   状态控制层     │ ← Pausable
├─────────────────┤
│   所有权层      │ ← Ownable
└─────────────────┘
```

### 审计友好设计
- **完整事件记录**：所有关键操作都有事件追踪
- **统一错误处理**：标准化的错误码和消息
- **权限透明化**：可查询的权限状态和历史

## 📚 文档和示例

- 📖 [完整 API 文档](./API_DOCUMENTATION.md)
- 🚀 [使用示例集](./USAGE_EXAMPLES.md)
- 🔍 [功能对比分析](./FUNCTIONALITY_COMPARISON.md)
- 🧪 [测试报告](./INTEGRATION_TEST_REPORT.md)

## 🏗️ 项目结构

```
move_module/
├── move/
│   ├── sources/
│   │   ├── ownable.move           # 所有权管理
│   │   ├── access_control.move    # 访问控制
│   │   ├── capability_store.move  # 能力管理
│   │   ├── pausable.move          # 暂停机制
│   │   ├── block_limiter.move     # 频率限制
│   │   └── comprehensive_test.move # 集成测试
│   └── Move.toml                  # 项目配置
├── API_DOCUMENTATION.md           # API 文档
├── USAGE_EXAMPLES.md              # 使用示例
└── FUNCTIONALITY_COMPARISON.md    # 功能对比
```

## 🚀 部署指南

### 测试网部署
```bash
# 编译检查
aptos move compile

# 运行测试
aptos move test

# 部署到测试网
aptos move publish --network testnet
```

### 主网部署
```bash
# 最终测试
aptos move test --coverage

# 部署到主网
aptos move publish --network mainnet
```

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- [Move 语言官方文档](https://move-language.github.io/move/)
- [Aptos 开发者文档](https://aptos.dev/guides/)
- [OpenZeppelin 合约库](https://github.com/OpenZeppelin/openzeppelin-contracts)

## ⚠️ 安全提醒

- 🔒 在生产环境使用前请进行充分测试
- 🛡️ 建议进行专业的安全审计
- 📊 监控关键事件和错误日志
- 🔄 定期检查权限配置的合理性
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