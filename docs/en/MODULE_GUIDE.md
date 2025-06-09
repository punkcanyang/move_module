# 🏗️ Move Security Modules Usage Guide

This guide provides detailed instructions for using the OpenZeppelin Move security modules in your blockchain applications.

## Quick Start

### 1. Add Dependencies

Add to your `Move.toml`:

```toml
[dependencies]
MoveStdlib = { git = "https://github.com/move-language/move.git", subdir = "language/move-stdlib", rev = "main" }
AptosFramework = { git = "https://github.com/aptos-labs/aptos-core.git", subdir = "aptos-move/framework/aptos-framework", rev = "main" }
MoveSecurityModules = { local = "../move" }
```

### 2. Import Modules

```move
module your_project::secure_contract {
    use move_security::ownable;
    use move_security::access_control;
    use move_security::pausable;
    use move_security::capability_store;
    use move_security::block_limiter;
}
```

### 3. Initialize Security

```move
public entry fun initialize(account: &signer) {
    // Basic ownership
    ownable::initialize_ownership(account);
    
    // Role-based access control
    access_control::initialize_access_control(account);
    
    // Emergency pause functionality
    pausable::initialize_pausable(account);
    
    // Rate limiting
    block_limiter::initialize_block_limiter(account, 10, 100, 1000);
    
    // Capability management
    capability_store::initialize_store<AdminCapability>(account);
}
```

## Module Documentation

### 🔐 Ownable Module

#### Purpose
Provides basic ownership functionality with secure transfer mechanisms.

#### Key Features
- Two-step ownership transfer
- Zero address protection
- Ownership renunciation
- Audit trail with timestamps

#### Usage Example

```move
module example::owned_token {
    use std::signer;
    use move_security::ownable;

    public entry fun initialize_token(creator: &signer) {
        ownable::initialize_ownership(creator);
    }

    public entry fun admin_mint(
        owner: &signer,
        to: address,
        amount: u64
    ) {
        // Only owner can mint
        let owner_addr = signer::address_of(owner);
        assert!(ownable::is_owner(owner_addr, owner_addr), 1);
        
        // Minting logic here
    }

    public entry fun transfer_ownership(
        current_owner: &signer,
        new_owner: address
    ) {
        ownable::transfer_ownership(current_owner, new_owner);
    }
}
```

#### Security Considerations
- Always validate the new owner address
- Use two-step transfer for critical systems
- Consider the implications of ownership renunciation

### 🎭 AccessControl Module

#### Purpose
Implements role-based access control (RBAC) for fine-grained permissions.

#### Key Features
- Hierarchical role system
- Role-based function access
- Dynamic role management
- Default admin role

#### Usage Example

```move
module example::role_based_system {
    use std::signer;
    use move_security::access_control;

    const MINTER_ROLE: vector<u8> = b"MINTER_ROLE";
    const BURNER_ROLE: vector<u8> = b"BURNER_ROLE";

    public entry fun setup_system(admin: &signer) {
        access_control::initialize_access_control(admin);
        
        // Setup custom roles
        access_control::setup_role(admin, MINTER_ROLE, access_control::default_admin_role());
        access_control::setup_role(admin, BURNER_ROLE, access_control::default_admin_role());
    }

    public entry fun grant_minter_role(
        admin: &signer,
        account: address
    ) {
        access_control::grant_role(admin, MINTER_ROLE, account);
    }

    public entry fun mint_tokens(
        minter: &signer,
        to: address,
        amount: u64
    ) {
        let minter_addr = signer::address_of(minter);
        assert!(access_control::has_role(minter_addr, MINTER_ROLE), 1);
        
        // Minting logic here
    }
}
```

#### Best Practices
- Use descriptive role names
- Implement role hierarchy carefully
- Regularly audit role assignments
- Use the principle of least privilege

### 🏪 CapabilityStore Module

#### Purpose
Manages capabilities for secure operations with delegation support.

#### Key Features
- Generic capability storage
- Capability delegation
- Delegation chain tracking
- Metadata management

#### Usage Example

```move
module example::capability_system {
    use std::signer;
    use std::string::String;
    use move_security::capability_store;

    struct AdminCapability has store {}
    struct MintingCapability has store {}

    public entry fun initialize_capabilities(admin: &signer) {
        capability_store::initialize_store<AdminCapability>(admin);
        capability_store::initialize_store<MintingCapability>(admin);
        
        // Store admin capability
        let admin_cap = AdminCapability {};
        capability_store::store_capability(admin, admin_cap);
        
        // Set metadata
        capability_store::set_metadata<AdminCapability>(
            admin, 
            string::utf8(b"role"), 
            string::utf8(b"super_admin")
        );
    }

    public entry fun delegate_minting(
        admin: &signer,
        delegate_to: address
    ) {
        // Extract admin capability to prove authorization
        let _admin_cap = capability_store::extract_capability<AdminCapability>(admin);
        
        // Create and delegate minting capability
        let mint_cap = MintingCapability {};
        capability_store::delegate_store(admin, delegate_to, mint_cap);
        
        // Store admin capability back
        capability_store::store_capability(admin, _admin_cap);
    }

    public entry fun mint_with_capability(
        minter: &signer,
        amount: u64
    ) {
        // Extract minting capability
        let _mint_cap = capability_store::extract_capability<MintingCapability>(minter);
        
        // Minting logic here
        
        // Store capability back
        capability_store::store_capability(minter, _mint_cap);
    }
}
```

#### Advanced Usage
- Use capabilities for permission delegation
- Track delegation chains for audit purposes
- Store metadata for capability management

### ⏸️ Pausable Module

#### Purpose
Provides emergency pause functionality for contracts.

#### Key Features
- Emergency pause/unpause
- Pause state checking
- Pause count tracking
- Authorized pauser management

#### Usage Example

```move
module example::pausable_service {
    use std::signer;
    use move_security::pausable;
    use move_security::ownable;

    public entry fun initialize_service(owner: &signer) {
        ownable::initialize_ownership(owner);
        pausable::initialize_pausable(owner);
    }

    public entry fun critical_operation(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Check if contract is not paused
        pausable::when_not_paused(user_addr);
        
        // Critical business logic here
    }

    public entry fun maintenance_operation(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Check if contract is paused (maintenance mode)
        pausable::when_paused(admin_addr);
        
        // Maintenance logic here
    }

    public entry fun emergency_pause(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        ownable::require_owner(owner_addr);
        
        pausable::pause(owner);
    }

    public entry fun resume_operations(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        ownable::require_owner(owner_addr);
        
        pausable::unpause(owner);
    }
}
```

#### Emergency Procedures
1. Identify the emergency situation
2. Call the pause function immediately
3. Investigate the issue
4. Fix the problem
5. Resume operations with unpause

### ⏱️ BlockLimiter Module

#### Purpose
Implements rate limiting based on block height and time intervals.

#### Key Features
- Multi-tier rate limiting (block/hour/day)
- Automatic counter reset
- Configurable limits
- Flood protection

#### Usage Example

```move
module example::rate_limited_service {
    use std::signer;
    use move_security::block_limiter;
    use move_security::ownable;

    public entry fun initialize_service(owner: &signer) {
        ownable::initialize_ownership(owner);
        
        // Allow 5 operations per block, 100 per hour, 500 per day
        block_limiter::initialize_block_limiter(owner, 5, 100, 500);
    }

    public entry fun limited_operation(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Check and update rate limits
        block_limiter::check_and_update_limits(user_addr);
        
        // Business logic here
    }

    public entry fun high_frequency_operation(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Check current usage before proceeding
        let (block_count, hour_count, day_count) = 
            block_limiter::get_current_limits(user_addr);
        
        // Custom logic based on current usage
        if (block_count < 3) {
            block_limiter::check_and_update_limits(user_addr);
            // High-priority operation
        } else {
            // Defer operation or use alternative method
        };
    }

    public entry fun update_rate_limits(
        owner: &signer,
        new_block_limit: u64,
        new_hour_limit: u64,
        new_day_limit: u64
    ) {
        let owner_addr = signer::address_of(owner);
        ownable::require_owner(owner_addr);
        
        block_limiter::update_limits(
            owner, 
            new_block_limit, 
            new_hour_limit, 
            new_day_limit
        );
    }
}
```

#### Rate Limiting Strategy
- Set appropriate limits based on use case
- Monitor usage patterns
- Adjust limits based on network conditions
- Implement graceful degradation

## Integration Patterns

### Multi-Module Security Architecture

```move
module enterprise::secure_platform {
    use std::signer;
    use std::string::String;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::pausable;
    use move_security::capability_store;
    use move_security::block_limiter;

    // Role definitions
    const ADMIN_ROLE: vector<u8> = b"ADMIN";
    const OPERATOR_ROLE: vector<u8> = b"OPERATOR";
    const USER_ROLE: vector<u8> = b"USER";

    struct PlatformCapability has store {}

    public entry fun initialize_platform(founder: &signer) {
        // Initialize all security modules
        ownable::initialize_ownership(founder);
        access_control::initialize_access_control(founder);
        pausable::initialize_pausable(founder);
        capability_store::initialize_store<PlatformCapability>(founder);
        block_limiter::initialize_block_limiter(founder, 20, 2000, 20000);
        
        // Setup role hierarchy
        let founder_addr = signer::address_of(founder);
        access_control::setup_role(founder, ADMIN_ROLE, access_control::default_admin_role());
        access_control::setup_role(founder, OPERATOR_ROLE, ADMIN_ROLE);
        access_control::setup_role(founder, USER_ROLE, OPERATOR_ROLE);
        
        // Grant founder admin role
        access_control::grant_role(founder, ADMIN_ROLE, founder_addr);
        
        // Store platform capability
        let platform_cap = PlatformCapability {};
        capability_store::store_capability(founder, platform_cap);
    }

    public entry fun secure_user_operation(user: &signer) {
        let user_addr = signer::address_of(user);
        
        // Multi-layer security checks
        pausable::when_not_paused(user_addr);
        assert!(access_control::has_role(user_addr, USER_ROLE), 1);
        block_limiter::check_and_update_limits(user_addr);
        
        // Business logic here
    }

    public entry fun admin_operation(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Admin-level security checks
        assert!(access_control::has_role(admin_addr, ADMIN_ROLE), 2);
        
        // Extract platform capability
        let _platform_cap = capability_store::extract_capability<PlatformCapability>(admin);
        
        // Admin business logic here
        
        // Store capability back
        capability_store::store_capability(admin, _platform_cap);
    }
}
```

### Event-Driven Architecture

```move
module events::security_events {
    use std::signer;
    use aptos_framework::event::{Self, EventHandle};
    use move_security::ownable;
    use move_security::access_control;

    struct SecurityEvents has key {
        ownership_transferred: EventHandle<OwnershipTransferEvent>,
        role_granted: EventHandle<RoleGrantedEvent>,
        emergency_paused: EventHandle<EmergencyPauseEvent>,
    }

    struct OwnershipTransferEvent has drop, store {
        previous_owner: address,
        new_owner: address,
        timestamp: u64,
    }

    struct RoleGrantedEvent has drop, store {
        role: vector<u8>,
        account: address,
        sender: address,
        timestamp: u64,
    }

    struct EmergencyPauseEvent has drop, store {
        pauser: address,
        reason: vector<u8>,
        timestamp: u64,
    }

    public entry fun initialize_events(account: &signer) {
        let events = SecurityEvents {
            ownership_transferred: event::new_event_handle<OwnershipTransferEvent>(account),
            role_granted: event::new_event_handle<RoleGrantedEvent>(account),
            emergency_paused: event::new_event_handle<EmergencyPauseEvent>(account),
        };
        move_to(account, events);
    }

    public fun emit_ownership_transfer(
        account: &signer,
        previous_owner: address,
        new_owner: address
    ) acquires SecurityEvents {
        let events = borrow_global_mut<SecurityEvents>(signer::address_of(account));
        event::emit_event(&mut events.ownership_transferred, OwnershipTransferEvent {
            previous_owner,
            new_owner,
            timestamp: aptos_framework::timestamp::now_seconds(),
        });
    }
}
```

## Testing Your Implementation

### Unit Testing

```move
#[test_only]
module your_project::test_secure_contract {
    use std::signer;
    use aptos_framework::account;
    use your_project::secure_contract;
    use move_security::ownable;

    #[test]
    fun test_initialization() {
        let owner = account::create_account_for_test(@0x1);
        secure_contract::initialize(&owner);
        
        assert!(ownable::is_owner(@0x1, @0x1), 1);
    }

    #[test]
    #[expected_failure(abort_code = 196611)] // E_NOT_OWNER
    fun test_unauthorized_access() {
        let owner = account::create_account_for_test(@0x1);
        let unauthorized = account::create_account_for_test(@0x2);
        
        secure_contract::initialize(&owner);
        secure_contract::admin_function(&unauthorized); // Should fail
    }
}
```

### Integration Testing

```move
#[test]
fun test_multi_module_integration() {
    let admin = account::create_account_for_test(@0x1);
    let user = account::create_account_for_test(@0x2);
    
    // Initialize all modules
    secure_contract::initialize(&admin);
    
    // Grant user role
    secure_contract::grant_user_role(&admin, @0x2);
    
    // Test user operation
    secure_contract::user_operation(&user);
    
    // Test pause functionality
    secure_contract::emergency_pause(&admin);
    
    // User operation should fail when paused
    // ... test code
}
```

## Deployment Guide

### 1. Preparation

```bash
# Compile the modules
aptos move compile

# Run tests
aptos move test

# Check for warnings
aptos move check
```

### 2. Testnet Deployment

```bash
# Deploy to devnet first
aptos move publish --profile devnet

# Test functionality
aptos move run --function-id "your_address::module::initialize"
```

### 3. Mainnet Deployment

```bash
# Deploy to mainnet (after thorough testing)
aptos move publish --profile mainnet
```

### 4. Post-Deployment Verification

```move
script {
    use your_project::secure_contract;
    
    fun verify_deployment(admin: &signer) {
        // Verify initialization
        assert!(secure_contract::is_initialized(), 1);
        
        // Test basic functionality
        secure_contract::test_function(admin);
    }
}
```

## Security Best Practices

### 1. Access Control
- Use role-based access control for complex permissions
- Implement the principle of least privilege
- Regularly audit role assignments
- Use capabilities for delegation

### 2. Emergency Procedures
- Always implement pausable functionality
- Have clear emergency response procedures
- Test emergency procedures regularly
- Document pause/unpause conditions

### 3. Rate Limiting
- Implement appropriate rate limits
- Monitor for abuse patterns
- Adjust limits based on usage
- Provide graceful degradation

### 4. Ownership Management
- Use two-step ownership transfer
- Validate all address inputs
- Consider multi-signature for critical operations
- Document ownership responsibilities

### 5. Testing and Monitoring
- Achieve 100% test coverage
- Implement formal verification
- Monitor contract health
- Set up alerting for suspicious activity

## Common Pitfalls and Solutions

### 1. Resource Not Found Errors
**Problem**: Calling functions before initialization
**Solution**: Always check if resources exist before operations

```move
public fun safe_operation(account: &signer) {
    let account_addr = signer::address_of(account);
    assert!(ownable::is_initialized(account_addr), E_NOT_INITIALIZED);
    
    // Continue with operation
}
```

### 2. Access Control Bypass
**Problem**: Not checking roles consistently
**Solution**: Use wrapper functions for role checks

```move
public fun require_admin(account: &signer) {
    let account_addr = signer::address_of(account);
    assert!(access_control::has_role(account_addr, ADMIN_ROLE), E_NOT_ADMIN);
}

public entry fun admin_function(admin: &signer) {
    require_admin(admin);
    // Admin logic here
}
```

### 3. Rate Limit Bypasses
**Problem**: Inconsistent rate limiting application
**Solution**: Create a standard rate checking pattern

```move
public fun check_rate_limits_and_execute<T>(
    user: &signer,
    operation: T
) {
    let user_addr = signer::address_of(user);
    block_limiter::check_and_update_limits(user_addr);
    
    // Execute operation
}
```

This guide provides the foundation for building secure, production-ready applications using the OpenZeppelin Move security modules. 