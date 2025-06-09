/// Move implementation of a capability management system
/// Provides secure capability storage and delegation mechanisms
module capability_store::capability_store {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::event;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::type_info;
    
    // Error codes
    const EUNAUTHORIZED: u64 = 1;
    const ECAPABILITY_NOT_FOUND: u64 = 2;
    const EALREADY_INITIALIZED: u64 = 3;
    const EINVALID_DELEGATION: u64 = 4;

    // Events
    #[event]
    struct CapabilityGranted has drop, store {
        capability_type: String,
        grantee: address,
        granter: address,
        can_delegate: bool,
    }

    #[event]
    struct CapabilityRevoked has drop, store {
        capability_type: String,
        revokee: address,
        revoker: address,
    }

    #[event]
    struct CapabilityDelegated has drop, store {
        capability_type: String,
        delegator: address,
        delegatee: address,
    }

    // Capability metadata
    struct CapabilityMetadata has store, drop {
        granted_by: address,
        can_delegate: bool,
        delegated_from: vector<address>, // Track delegation chain
    }

    // Capability store resource
    struct CapabilityStore has key {
        capabilities: SmartTable<String, CapabilityMetadata>,
        delegated_capabilities: SmartTable<String, vector<address>>,
    }

    // Initialize capability store
    public fun initialize(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<CapabilityStore>(account_addr), error::already_exists(EALREADY_INITIALIZED));
        
        move_to(account, CapabilityStore {
            capabilities: smart_table::new<String, CapabilityMetadata>(),
            delegated_capabilities: smart_table::new<String, vector<address>>(),
        });
    }

    // Grant a capability to an address
    public fun grant_capability<T: store + drop>(
        granter: &signer,
        grantee_addr: address,
        capability: T,
        can_delegate: bool
    ) acquires CapabilityStore {
        let granter_addr = signer::address_of(granter);
        let capability_type = get_type_name<T>();
        
        // Ensure grantee has capability store
        assert!(exists<CapabilityStore>(grantee_addr), error::not_found(ECAPABILITY_NOT_FOUND));
        
        let grantee_store = borrow_global_mut<CapabilityStore>(grantee_addr);
        
        // Store capability metadata
        if (!smart_table::contains(&grantee_store.capabilities, capability_type)) {
            smart_table::add(&mut grantee_store.capabilities, capability_type, CapabilityMetadata {
                granted_by: granter_addr,
                can_delegate,
                delegated_from: vector::empty<address>(),
            });
        } else {
            let metadata = smart_table::borrow_mut(&mut grantee_store.capabilities, capability_type);
            metadata.granted_by = granter_addr;
            metadata.can_delegate = can_delegate;
        };
        
        // Store the actual capability (placeholder implementation)
        store_capability<T>(grantee_addr, capability);

        event::emit(CapabilityGranted {
            capability_type,
            grantee: grantee_addr,
            granter: granter_addr,
            can_delegate,
        });
    }

    // Revoke a capability from an address
    public fun revoke_capability<T: store + drop>(
        revoker: &signer,
        revokee_addr: address
    ) acquires CapabilityStore {
        let revoker_addr = signer::address_of(revoker);
        let capability_type = get_type_name<T>();
        
        assert!(exists<CapabilityStore>(revokee_addr), error::not_found(ECAPABILITY_NOT_FOUND));
        let store = borrow_global_mut<CapabilityStore>(revokee_addr);
        
        assert!(smart_table::contains(&store.capabilities, capability_type),
                error::not_found(ECAPABILITY_NOT_FOUND));
        
        let metadata = smart_table::borrow(&store.capabilities, capability_type);
        
        // Only the original granter can revoke (unless it's self-revocation)
        assert!(metadata.granted_by == revoker_addr || revoker_addr == revokee_addr,
                error::permission_denied(EUNAUTHORIZED));
        
        // Remove capability metadata
        smart_table::remove(&mut store.capabilities, capability_type);
        
        // Remove delegated capabilities tracking
        if (smart_table::contains(&store.delegated_capabilities, capability_type)) {
            smart_table::remove(&mut store.delegated_capabilities, capability_type);
        };
        
        // Remove the actual capability
        remove_capability<T>(revokee_addr);

        event::emit(CapabilityRevoked {
            capability_type,
            revokee: revokee_addr,
            revoker: revoker_addr,
        });
    }

    // Delegate a capability to another address
    public fun delegate_capability<T: store + drop>(
        delegator: &signer,
        delegatee_addr: address,
        capability: T
    ) acquires CapabilityStore {
        let delegator_addr = signer::address_of(delegator);
        let capability_type = get_type_name<T>();
        
        // Check if delegator has the capability and can delegate
        assert!(exists<CapabilityStore>(delegator_addr), error::not_found(ECAPABILITY_NOT_FOUND));
        
        // Ensure delegatee has capability store
        assert!(exists<CapabilityStore>(delegatee_addr), error::not_found(ECAPABILITY_NOT_FOUND));
        
        // Get delegator metadata first (separate scope to avoid borrow conflicts)
        let (granted_by, _can_delegate, delegated_from) = {
            let delegator_store = borrow_global<CapabilityStore>(delegator_addr);
            assert!(smart_table::contains(&delegator_store.capabilities, capability_type),
                    error::not_found(ECAPABILITY_NOT_FOUND));
            
            let delegator_metadata = smart_table::borrow(&delegator_store.capabilities, capability_type);
            assert!(delegator_metadata.can_delegate, error::permission_denied(EUNAUTHORIZED));
            
            (delegator_metadata.granted_by, delegator_metadata.can_delegate, delegator_metadata.delegated_from)
        };
        
        // Create delegation metadata
        let delegation_chain = vector::empty<address>();
        let i = 0;
        while (i < vector::length(&delegated_from)) {
            vector::push_back(&mut delegation_chain, *vector::borrow(&delegated_from, i));
            i = i + 1;
        };
        vector::push_back(&mut delegation_chain, delegator_addr);
        
        // Now safely borrow delegatee store
        let delegatee_store = borrow_global_mut<CapabilityStore>(delegatee_addr);
        
        // Store capability metadata for delegatee
        if (!smart_table::contains(&delegatee_store.capabilities, capability_type)) {
            smart_table::add(&mut delegatee_store.capabilities, capability_type, CapabilityMetadata {
                granted_by,
                can_delegate: false, // Delegated capabilities cannot be further delegated
                delegated_from: delegation_chain,
            });
        };
        
        // Track delegation
        if (!smart_table::contains(&delegatee_store.delegated_capabilities, capability_type)) {
            smart_table::add(&mut delegatee_store.delegated_capabilities, capability_type, vector::empty<address>());
        };
        let delegated_list = smart_table::borrow_mut(&mut delegatee_store.delegated_capabilities, capability_type);
        vector::push_back(delegated_list, delegator_addr);
        
        // Store the delegated capability
        store_capability<T>(delegatee_addr, capability);

        event::emit(CapabilityDelegated {
            capability_type,
            delegator: delegator_addr,
            delegatee: delegatee_addr,
        });
    }

    // Check if an address has a specific capability
    public fun has_capability<T>(addr: address): bool acquires CapabilityStore {
        if (!exists<CapabilityStore>(addr)) {
            return false
        };
        
        let capability_type = get_type_name<T>();
        let store = borrow_global<CapabilityStore>(addr);
        smart_table::contains(&store.capabilities, capability_type)
    }

    // Get capability metadata
    public fun get_capability_metadata<T>(addr: address): (address, bool, vector<address>) acquires CapabilityStore {
        let capability_type = get_type_name<T>();
        let store = borrow_global<CapabilityStore>(addr);
        
        assert!(smart_table::contains(&store.capabilities, capability_type),
                error::not_found(ECAPABILITY_NOT_FOUND));
        
        let metadata = smart_table::borrow(&store.capabilities, capability_type);
        (metadata.granted_by, metadata.can_delegate, metadata.delegated_from)
    }

    // Assert that caller has specific capability
    public fun assert_capability<T>(caller: &signer) acquires CapabilityStore {
        let caller_addr = signer::address_of(caller);
        assert!(has_capability<T>(caller_addr), error::permission_denied(EUNAUTHORIZED));
    }

    // Helper function to get type name as string
    fun get_type_name<T>(): String {
        let type_info = type_info::type_of<T>();
        let module_name = type_info::module_name(&type_info);
        let struct_name = type_info::struct_name(&type_info);
        // Combine module and struct name
        let full_name = module_name;
        vector::append(&mut full_name, b"::");
        vector::append(&mut full_name, struct_name);
        std::string::utf8(full_name)
    }

    // Store capability in the account's resource (placeholder - would need actual implementation)
    fun store_capability<T: store + drop>(_addr: address, _capability: T) {
        // In a real implementation, you would store this as a resource
        // For now, we don't store anything since we can't store arbitrary types
        // In practice, you'd have a generic resource wrapper
    }

    // Remove capability from account (placeholder)
    fun remove_capability<T: store + drop>(_addr: address) {
        // In a real implementation, you would remove the resource
        // This is a placeholder
    }

    // Example capability types for testing
    struct AdminCapability has store, drop {}
    struct MinterCapability has store, drop {}
    struct PauserCapability has store, drop {}

    #[test_only]
    public fun create_admin_capability(): AdminCapability {
        AdminCapability {}
    }

    #[test_only]
    public fun create_minter_capability(): MinterCapability {
        MinterCapability {}
    }

    #[test(granter = @0x123, grantee = @0x456)]
    public fun test_capability_grant_and_revoke(granter: &signer, grantee: &signer) acquires CapabilityStore {
        let granter_addr = signer::address_of(granter);
        let grantee_addr = signer::address_of(grantee);
        
        // Initialize stores
        initialize(granter);
        initialize(grantee);
        
        // Grant admin capability
        let admin_cap = create_admin_capability();
        grant_capability<AdminCapability>(granter, grantee_addr, admin_cap, true);
        
        // Verify capability granted
        assert!(has_capability<AdminCapability>(grantee_addr), 1);
        
        // Revoke capability
        revoke_capability<AdminCapability>(granter, grantee_addr);
        
        // Verify capability revoked
        assert!(!has_capability<AdminCapability>(grantee_addr), 2);
    }

    #[test(delegator = @0x123, delegatee = @0x456, granter = @0x789)]
    public fun test_capability_delegation(delegator: &signer, delegatee: &signer, granter: &signer) acquires CapabilityStore {
        let delegator_addr = signer::address_of(delegator);
        let delegatee_addr = signer::address_of(delegatee);
        let granter_addr = signer::address_of(granter);
        
        // Initialize stores
        initialize(granter);
        initialize(delegator);
        initialize(delegatee);
        
        // Grant capability to delegator
        let admin_cap1 = create_admin_capability();
        grant_capability<AdminCapability>(granter, delegator_addr, admin_cap1, true);
        
        // Delegate capability
        let admin_cap2 = create_admin_capability();
        delegate_capability<AdminCapability>(delegator, delegatee_addr, admin_cap2);
        
        // Verify delegation
        assert!(has_capability<AdminCapability>(delegatee_addr), 1);
        
        let (granted_by, can_delegate, delegated_from) = get_capability_metadata<AdminCapability>(delegatee_addr);
        assert!(granted_by == granter_addr, 2);
        assert!(!can_delegate, 3); // Delegated capabilities cannot be further delegated
        assert!(vector::length(&delegated_from) == 1, 4);
    }
} 