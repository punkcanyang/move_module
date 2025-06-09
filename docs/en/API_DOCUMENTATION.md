# 📖 OpenZeppelin Move API Reference Documentation

This document provides a comprehensive API reference for all modules in the OpenZeppelin Move security suite.

## Table of Contents

1. [Ownable Module](#ownable-module)
2. [AccessControl Module](#accesscontrol-module)
3. [CapabilityStore Module](#capabilitystore-module)
4. [Pausable Module](#pausable-module)
5. [BlockLimiter Module](#blocklimiter-module)

---

## Ownable Module

The `Ownable` module provides basic authorization control functions, implementing ownership-based access control.

### Data Structures

#### OwnershipInfo
```move
struct OwnershipInfo has key, store {
    owner: address,
    pending_owner: Option<address>,
    created_at: u64,
    transferred_at: u64,
}
```

**Fields:**
- `owner`: Current owner address
- `pending_owner`: Pending new owner address (for two-step transfer)
- `created_at`: Creation timestamp
- `transferred_at`: Last transfer timestamp

### Functions

#### Initialize Ownership
```move
public fun initialize_ownership(account: &signer)
```

**Parameters:**
- `account`: Signer representing the initial owner

**Description:** Initializes ownership for the calling account.

**Errors:**
- `196609`: Already initialized
- `196610`: Invalid operation

**Example:**
```move
public entry fun init_my_contract(account: &signer) {
    ownable::initialize_ownership(account);
}
```

#### Transfer Ownership
```move
public fun transfer_ownership(account: &signer, new_owner: address)
```

**Parameters:**
- `account`: Current owner's signer
- `new_owner`: New owner's address

**Description:** Initiates ownership transfer (requires acceptance).

**Errors:**
- `196611`: Not owner
- `196612`: Zero address

#### Accept Ownership
```move
public fun accept_ownership(account: &signer, previous_owner: address)
```

**Parameters:**
- `account`: New owner's signer
- `previous_owner`: Previous owner's address

**Description:** Accepts pending ownership transfer.

#### Renounce Ownership
```move
public fun renounce_ownership(account: &signer)
```

**Parameters:**
- `account`: Current owner's signer

**Description:** Permanently renounces ownership (irreversible).

### View Functions

#### Get Owner
```move
public fun get_owner(owner_addr: address): address
```

**Returns:** Current owner address

#### Is Owner
```move
public fun is_owner(owner_addr: address, check_addr: address): bool
```

**Returns:** True if check_addr is the owner

---

## AccessControl Module

Implements role-based access control (RBAC) with hierarchical permissions.

### Data Structures

#### AccessControlInfo
```move
struct AccessControlInfo has key, store {
    roles: SimpleMap<vector<u8>, RoleData>,
    admin_roles: SimpleMap<vector<u8>, vector<u8>>,
    created_at: u64,
}
```

#### RoleData
```move
struct RoleData has store, drop {
    members: vector<address>,
    created_at: u64,
}
```

### Constants

#### Default Admin Role
```move
const DEFAULT_ADMIN_ROLE: vector<u8> = b"DEFAULT_ADMIN_ROLE";
```

### Functions

#### Initialize Access Control
```move
public fun initialize_access_control(account: &signer)
```

**Parameters:**
- `account`: Signer for the account

**Description:** Initializes access control and grants DEFAULT_ADMIN_ROLE to the caller.

#### Grant Role
```move
public fun grant_role(admin: &signer, role: vector<u8>, account: address)
```

**Parameters:**
- `admin`: Admin signer
- `role`: Role identifier
- `account`: Account to grant role to

**Description:** Grants a role to an account.

**Errors:**
- `327683`: Missing role
- `327684`: Access denied

#### Revoke Role
```move
public fun revoke_role(admin: &signer, role: vector<u8>, account: address)
```

**Parameters:**
- `admin`: Admin signer
- `role`: Role identifier
- `account`: Account to revoke role from

**Description:** Revokes a role from an account.

#### Setup Role
```move
public fun setup_role(account: &signer, role: vector<u8>, admin_role: vector<u8>)
```

**Parameters:**
- `account`: Account signer
- `role`: New role identifier
- `admin_role`: Admin role for the new role

**Description:** Sets up a new role with its admin role.

### View Functions

#### Has Role
```move
public fun has_role(account_addr: address, role: vector<u8>): bool
```

**Returns:** True if the account has the specified role

#### Get Role Admin
```move
public fun get_role_admin(account_addr: address, role: vector<u8>): vector<u8>
```

**Returns:** Admin role for the specified role

---

## CapabilityStore Module

Manages generic capabilities with delegation and metadata support.

### Data Structures

#### CapabilityStore
```move
struct CapabilityStore<phantom T> has key, store {
    capabilities: vector<T>,
    delegated_from: Option<address>,
    delegation_chain: vector<address>,
    metadata: SimpleMap<String, String>,
    created_at: u64,
}
```

### Functions

#### Initialize Store
```move
public fun initialize_store<T: store>(account: &signer)
```

**Parameters:**
- `account`: Account signer

**Description:** Initializes capability store for type T.

#### Store Capability
```move
public fun store_capability<T: store>(account: &signer, capability: T)
```

**Parameters:**
- `account`: Account signer
- `capability`: Capability to store

**Description:** Stores a capability in the account's store.

#### Extract Capability
```move
public fun extract_capability<T: store>(account: &signer): T
```

**Parameters:**
- `account`: Account signer

**Returns:** Extracted capability

**Description:** Extracts and returns a capability from the store.

#### Delegate Store
```move
public fun delegate_store<T: store>(
    from: &signer,
    to: address,
    capability: T
)
```

**Parameters:**
- `from`: Delegator signer
- `to`: Delegate address
- `capability`: Capability to delegate

**Description:** Delegates a capability to another account.

### Metadata Functions

#### Set Metadata
```move
public fun set_metadata<T: store>(
    account: &signer,
    key: String,
    value: String
)
```

**Parameters:**
- `account`: Account signer
- `key`: Metadata key
- `value`: Metadata value

**Description:** Sets metadata for the capability store.

#### Get Metadata
```move
public fun get_metadata<T: store>(account_addr: address, key: String): Option<String>
```

**Returns:** Metadata value if exists

---

## Pausable Module

Implements emergency pause functionality for smart contracts.

### Data Structures

#### PauseInfo
```move
struct PauseInfo has key, store {
    paused: bool,
    pauser: address,
    paused_at: u64,
    pause_count: u64,
}
```

### Functions

#### Initialize Pausable
```move
public fun initialize_pausable(account: &signer)
```

**Parameters:**
- `account`: Account signer

**Description:** Initializes pausable functionality.

#### Pause
```move
public fun pause(account: &signer)
```

**Parameters:**
- `account`: Pauser signer

**Description:** Pauses the contract.

**Errors:**
- `851969`: Already paused

#### Unpause
```move
public fun unpause(account: &signer)
```

**Parameters:**
- `account`: Pauser signer

**Description:** Unpauses the contract.

**Errors:**
- `851970`: Not paused

### Modifier Functions

#### When Not Paused
```move
public fun when_not_paused(account_addr: address)
```

**Parameters:**
- `account_addr`: Account address to check

**Description:** Ensures the contract is not paused.

**Errors:**
- `851971`: Contract is paused

#### When Paused
```move
public fun when_paused(account_addr: address)
```

**Parameters:**
- `account_addr`: Account address to check

**Description:** Ensures the contract is paused.

**Errors:**
- `851972`: Contract is not paused

### View Functions

#### Is Paused
```move
public fun is_paused(account_addr: address): bool
```

**Returns:** True if the contract is paused

---

## BlockLimiter Module

Implements rate limiting based on block height and time intervals.

### Data Structures

#### BlockLimitInfo
```move
struct BlockLimitInfo has key, store {
    limit_per_block: u64,
    limit_per_hour: u64,
    limit_per_day: u64,
    current_block_count: u64,
    current_hour_count: u64,
    current_day_count: u64,
    last_block_height: u64,
    last_hour_timestamp: u64,
    last_day_timestamp: u64,
    created_at: u64,
}
```

### Functions

#### Initialize Block Limiter
```move
public fun initialize_block_limiter(
    account: &signer,
    limit_per_block: u64,
    limit_per_hour: u64,
    limit_per_day: u64
)
```

**Parameters:**
- `account`: Account signer
- `limit_per_block`: Maximum operations per block
- `limit_per_hour`: Maximum operations per hour
- `limit_per_day`: Maximum operations per day

**Description:** Initializes rate limiting with specified limits.

#### Check And Update Limits
```move
public fun check_and_update_limits(account_addr: address)
```

**Parameters:**
- `account_addr`: Account address to check

**Description:** Checks current limits and updates counters.

**Errors:**
- `982017`: Block limit exceeded
- `982018`: Hour limit exceeded
- `982019`: Day limit exceeded

#### Update Limits
```move
public fun update_limits(
    account: &signer,
    limit_per_block: u64,
    limit_per_hour: u64,
    limit_per_day: u64
)
```

**Parameters:**
- `account`: Account signer
- `limit_per_block`: New block limit
- `limit_per_hour`: New hour limit
- `limit_per_day`: New day limit

**Description:** Updates rate limiting parameters.

### View Functions

#### Get Current Limits
```move
public fun get_current_limits(account_addr: address): (u64, u64, u64)
```

**Returns:** Tuple of (block_count, hour_count, day_count)

#### Get Limit Settings
```move
public fun get_limit_settings(account_addr: address): (u64, u64, u64)
```

**Returns:** Tuple of (limit_per_block, limit_per_hour, limit_per_day)

---

## Error Codes Reference

### Ownable Module
- `196609`: `E_ALREADY_INITIALIZED` - Ownership already initialized
- `196610`: `E_INVALID_OPERATION` - Invalid operation
- `196611`: `E_NOT_OWNER` - Caller is not the owner
- `196612`: `E_ZERO_ADDRESS` - Zero address not allowed

### AccessControl Module
- `327683`: `E_MISSING_ROLE` - Account missing required role
- `327684`: `E_ACCESS_DENIED` - Access denied
- `327685`: `E_ROLE_NOT_FOUND` - Role not found

### CapabilityStore Module
- `458753`: `E_STORE_NOT_FOUND` - Capability store not found
- `458754`: `E_CAPABILITY_NOT_FOUND` - Capability not found
- `458755`: `E_INVALID_DELEGATION` - Invalid delegation

### Pausable Module
- `851969`: `E_ALREADY_PAUSED` - Contract already paused
- `851970`: `E_NOT_PAUSED` - Contract not paused
- `851971`: `E_PAUSED` - Contract is paused
- `851972`: `E_NOT_PAUSED_STATE` - Contract not in paused state

### BlockLimiter Module
- `982017`: `E_BLOCK_LIMIT_EXCEEDED` - Block limit exceeded
- `982018`: `E_HOUR_LIMIT_EXCEEDED` - Hour limit exceeded
- `982019`: `E_DAY_LIMIT_EXCEEDED` - Day limit exceeded

---

## Integration Examples

### Basic Contract with Multiple Modules
```move
module example::secure_contract {
    use move_security::ownable;
    use move_security::pausable;
    use move_security::access_control;
    
    public entry fun initialize(account: &signer) {
        ownable::initialize_ownership(account);
        pausable::initialize_pausable(account);
        access_control::initialize_access_control(account);
    }
    
    public entry fun admin_function(account: &signer) {
        ownable::require_owner(signer::address_of(account));
        pausable::when_not_paused(signer::address_of(account));
        // Admin logic here
    }
}
```

This completes the comprehensive API reference documentation for all modules in the OpenZeppelin Move security suite. 