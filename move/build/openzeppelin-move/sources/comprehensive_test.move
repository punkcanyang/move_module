/// Comprehensive test module that demonstrates integration of all five security modules
/// Tests: Ownable, AccessControl, CapabilityStore, Pausable, BlockLimiter
module comprehensive_test::comprehensive_test {
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::event;
    
    // Import all five security modules
    use ownable::ownable;
    use access_control::access_control;
    use capability_store::capability_store;
    use pausable::pausable;
    use block_limiter::block_limiter;

    // Events for testing
    #[event]
    struct TokenMinted has drop, store {
        to: address,
        amount: u64,
        minter: address,
    }

    #[event]
    struct AdminActionPerformed has drop, store {
        admin: address,
        action: String,
    }

    // Test resource that combines all security features
    struct SecureToken has key {
        total_supply: u64,
        name: String,
    }

    // Custom capabilities for testing
    struct MintCapability has store, drop {}
    struct BurnCapability has store, drop {}
    struct AdminCapability has store, drop {}

    // Test role definitions (using string constants)
    const MINTER_ROLE: vector<u8> = b"MINTER_ROLE";
    const BURNER_ROLE: vector<u8> = b"BURNER_ROLE";
    const PAUSER_ROLE: vector<u8> = b"PAUSER_ROLE";

    // Initialize the comprehensive test contract with all security modules
    public entry fun initialize_comprehensive_test(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // 1. Initialize Ownable
        ownable::initialize(admin);
        
        // 2. Initialize AccessControl
        access_control::initialize(admin);
        
        // 3. Initialize CapabilityStore
        capability_store::initialize(admin);
        
        // 4. Initialize Pausable
        pausable::initialize(admin);
        
        // 5. Initialize BlockLimiter with test parameters
        block_limiter::initialize(
            admin,
            5,    // max_accesses_per_block_window
            100,  // block_window_size
            10,   // max_accesses_per_time_window
            60000000, // time_window_size (60 seconds)
            1,    // block_cooldown
            1000000  // time_cooldown (1 second)
        );
        
        // Create test token
        move_to(admin, SecureToken {
            total_supply: 0,
            name: string::utf8(b"SecureTestToken"),
        });
        
        // Setup initial roles
        let minter_role = string::utf8(MINTER_ROLE);
        let burner_role = string::utf8(BURNER_ROLE);
        let pauser_role = string::utf8(PAUSER_ROLE);
        
        // Grant roles to admin
        access_control::grant_role(admin, admin_addr, minter_role, admin_addr);
        access_control::grant_role(admin, admin_addr, burner_role, admin_addr);
        access_control::grant_role(admin, admin_addr, pauser_role, admin_addr);
        
        // Grant capabilities to admin
        capability_store::grant_capability<MintCapability>(admin, admin_addr, MintCapability {}, true);
        capability_store::grant_capability<BurnCapability>(admin, admin_addr, BurnCapability {}, true);
        capability_store::grant_capability<AdminCapability>(admin, admin_addr, AdminCapability {}, false);
    }

    // Test function that requires multiple security checks
    public entry fun secure_mint(
        minter: &signer,
        token_contract: address,
        amount: u64,
        to: address
    ) acquires SecureToken {
        let minter_addr = signer::address_of(minter);
        
        // 1. Check if contract is not paused
        pausable::when_not_paused(token_contract);
        
        // 2. Check rate limiting
        block_limiter::require_access(minter, token_contract);
        
        // 3. Check ownership or role permission
        let has_owner_permission = ownable::is_owner(minter, token_contract);
        let minter_role = string::utf8(MINTER_ROLE);
        let has_role_permission = access_control::has_role(token_contract, minter_role, minter_addr);
        
        assert!(has_owner_permission || has_role_permission, 1);
        
        // 4. Check capability
        capability_store::assert_capability<MintCapability>(minter);
        
        // Perform minting
        let token = borrow_global_mut<SecureToken>(token_contract);
        token.total_supply = token.total_supply + amount;
        
        event::emit(TokenMinted {
            to,
            amount,
            minter: minter_addr,
        });
    }

    // Test admin function with multiple security layers
    public entry fun admin_pause_contract(admin: &signer, contract_addr: address) {
        let admin_addr = signer::address_of(admin);
        
        // 1. Check ownership
        ownable::only_owner(admin, contract_addr);
        
        // 2. Check admin role
        let pauser_role = string::utf8(PAUSER_ROLE);
        access_control::only_role(admin, contract_addr, pauser_role);
        
        // 3. Check admin capability
        capability_store::assert_capability<AdminCapability>(admin);
        
        // 4. Pause the contract
        pausable::pause(admin, contract_addr);
        
        event::emit(AdminActionPerformed {
            admin: admin_addr,
            action: string::utf8(b"CONTRACT_PAUSED"),
        });
    }

    // Test capability delegation
    public entry fun delegate_mint_capability(
        delegator: &signer,
        delegatee_addr: address
    ) {
        // Check if delegator has the capability
        capability_store::assert_capability<MintCapability>(delegator);
        
        // Delegate capability
        capability_store::delegate_capability<MintCapability>(
            delegator,
            delegatee_addr,
            MintCapability {}
        );
    }

    // Test role management
    public entry fun grant_minter_role(
        admin: &signer,
        contract_addr: address,
        new_minter: address
    ) {
        // Only admin can grant roles
        ownable::only_owner(admin, contract_addr);
        
        let minter_role = string::utf8(MINTER_ROLE);
        access_control::grant_role(admin, contract_addr, minter_role, new_minter);
    }

    // Test emergency stop
    public entry fun emergency_stop(admin: &signer, contract_addr: address) {
        // Owner can emergency stop
        ownable::only_owner(admin, contract_addr);
        
        // Pause all operations
        pausable::pause(admin, contract_addr);
        
        event::emit(AdminActionPerformed {
            admin: signer::address_of(admin),
            action: string::utf8(b"EMERGENCY_STOP"),
        });
    }

    // View functions for testing
    public fun get_token_supply(contract_addr: address): u64 acquires SecureToken {
        borrow_global<SecureToken>(contract_addr).total_supply
    }

    public fun is_contract_paused(contract_addr: address): bool {
        pausable::is_paused(contract_addr)
    }

    public fun get_owner(contract_addr: address): address {
        ownable::owner(contract_addr)
    }

    public fun check_minter_role(contract_addr: address, account: address): bool {
        let minter_role = string::utf8(MINTER_ROLE);
        access_control::has_role(contract_addr, minter_role, account)
    }

    public fun check_mint_capability(account: address): bool {
        capability_store::has_capability<MintCapability>(account)
    }

    // Helper functions for testing
    #[test_only]
    public fun create_mint_capability(): MintCapability {
        MintCapability {}
    }

    #[test_only]
    public fun create_admin_capability(): AdminCapability {
        AdminCapability {}
    }

    // Comprehensive integration tests
    #[test(admin = @0x123, user = @0x456)]
    public fun test_full_integration(admin: &signer, user: &signer) acquires SecureToken {
        let admin_addr = signer::address_of(admin);
        let user_addr = signer::address_of(user);
        
        // Initialize everything
        initialize_comprehensive_test(admin);
        
        // Test 1: Check initial state
        assert!(get_owner(admin_addr) == admin_addr, 1);
        assert!(!is_contract_paused(admin_addr), 2);
        assert!(check_minter_role(admin_addr, admin_addr), 3);
        assert!(check_mint_capability(admin_addr), 4);
        assert!(get_token_supply(admin_addr) == 0, 5);
        
        // Test 2: Secure mint by admin
        secure_mint(admin, admin_addr, 100, user_addr);
        assert!(get_token_supply(admin_addr) == 100, 6);
        
        // Test 3: Grant role to user
        grant_minter_role(admin, admin_addr, user_addr);
        assert!(check_minter_role(admin_addr, user_addr), 7);
        
        // Test 4: Initialize capability store for user
        capability_store::initialize(user);
        
        // Test 5: Delegate capability to user
        delegate_mint_capability(admin, user_addr);
        assert!(check_mint_capability(user_addr), 8);
        
        // Test 6: User can now mint (has both role and capability)
        secure_mint(user, admin_addr, 50, user_addr);
        assert!(get_token_supply(admin_addr) == 150, 9);
        
        // Test 7: Admin pauses contract
        admin_pause_contract(admin, admin_addr);
        assert!(is_contract_paused(admin_addr), 10);
    }

    #[test(admin = @0x123)]
    #[expected_failure(abort_code = 851969, location = pausable::pausable)]
    public fun test_paused_operations_fail(admin: &signer) acquires SecureToken {
        let admin_addr = signer::address_of(admin);
        
        // Initialize and pause
        initialize_comprehensive_test(admin);
        pausable::pause(admin, admin_addr);
        
        // This should fail because contract is paused
        secure_mint(admin, admin_addr, 100, admin_addr);
    }

    #[test(admin = @0x123, non_admin = @0x456)]
    #[expected_failure(abort_code = 327681, location = ownable::ownable)]
    public fun test_non_admin_cannot_pause(admin: &signer, non_admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Initialize
        initialize_comprehensive_test(admin);
        
        // Non-admin should not be able to pause
        admin_pause_contract(non_admin, admin_addr);
    }

    #[test(admin = @0x123, user = @0x456)]
    #[expected_failure(abort_code = 1, location = Self)]
    public fun test_unauthorized_mint(admin: &signer, user: &signer) acquires SecureToken {
        let admin_addr = signer::address_of(admin);
        
        // Initialize
        initialize_comprehensive_test(admin);
        
        // User without role or capability should not be able to mint
        secure_mint(user, admin_addr, 100, signer::address_of(user));
    }

    #[test(admin = @0x123)]
    public fun test_ownership_transfer(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        let new_owner = @0x789;
        
        // Initialize
        initialize_comprehensive_test(admin);
        
        // Transfer ownership
        ownable::transfer_ownership(admin, admin_addr, new_owner);
        assert!(get_owner(admin_addr) == new_owner, 1);
    }
} 