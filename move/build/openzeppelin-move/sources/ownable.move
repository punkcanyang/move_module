/// Move implementation of OpenZeppelin's Ownable contract
/// Provides basic authorization control functions, simplifying the implementation of user permissions
module ownable::ownable {
    use std::error;
    use std::signer;
    use aptos_framework::event;
    
    // Error codes
    const EUNAUTHORIZED: u64 = 1;
    const EINVALID_OWNER: u64 = 2;
    const EALREADY_INITIALIZED: u64 = 3;

    // Events
    #[event]
    struct OwnershipTransferred has drop, store {
        previous_owner: address,
        new_owner: address,
    }

    // Owner resource
    struct OwnershipInfo has key {
        owner: address,
    }

    // Initialize ownership with the deployer as initial owner
    public fun initialize(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<OwnershipInfo>(account_addr), error::already_exists(EALREADY_INITIALIZED));
        
        move_to(account, OwnershipInfo {
            owner: account_addr,
        });

        event::emit(OwnershipTransferred {
            previous_owner: @0x0,
            new_owner: account_addr,
        });
    }

    // Initialize ownership with a specific owner
    public fun initialize_with_owner(deployer: &signer, initial_owner: address) {
        let deployer_addr = signer::address_of(deployer);
        assert!(!exists<OwnershipInfo>(deployer_addr), error::already_exists(EALREADY_INITIALIZED));
        assert!(initial_owner != @0x0, error::invalid_argument(EINVALID_OWNER));
        
        move_to(deployer, OwnershipInfo {
            owner: initial_owner,
        });

        event::emit(OwnershipTransferred {
            previous_owner: @0x0,
            new_owner: initial_owner,
        });
    }

    // Get the current owner
    public fun owner(contract_addr: address): address acquires OwnershipInfo {
        borrow_global<OwnershipInfo>(contract_addr).owner
    }

    // Check if the caller is the owner
    public fun is_owner(caller: &signer, contract_addr: address): bool acquires OwnershipInfo {
        let caller_addr = signer::address_of(caller);
        owner(contract_addr) == caller_addr
    }

    // Assert that the caller is the owner
    public fun assert_owner(caller: &signer, contract_addr: address) acquires OwnershipInfo {
        assert!(is_owner(caller, contract_addr), error::permission_denied(EUNAUTHORIZED));
    }

    // Transfer ownership to a new owner
    public fun transfer_ownership(owner: &signer, contract_addr: address, new_owner: address) acquires OwnershipInfo {
        assert_owner(owner, contract_addr);
        assert!(new_owner != @0x0, error::invalid_argument(EINVALID_OWNER));
        
        let ownership_info = borrow_global_mut<OwnershipInfo>(contract_addr);
        let previous_owner = ownership_info.owner;
        ownership_info.owner = new_owner;

        event::emit(OwnershipTransferred {
            previous_owner,
            new_owner,
        });
    }

    // Renounce ownership (set owner to zero address)
    public fun renounce_ownership(owner: &signer, contract_addr: address) acquires OwnershipInfo {
        assert_owner(owner, contract_addr);
        
        let ownership_info = borrow_global_mut<OwnershipInfo>(contract_addr);
        let previous_owner = ownership_info.owner;
        ownership_info.owner = @0x0;

        event::emit(OwnershipTransferred {
            previous_owner,
            new_owner: @0x0,
        });
    }

    // Helper function for contracts to easily check owner access
    public fun only_owner(caller: &signer, contract_addr: address) acquires OwnershipInfo {
        assert_owner(caller, contract_addr);
    }

    #[test(account = @0x123)]
    public fun test_ownership_initialization(account: &signer) acquires OwnershipInfo {
        let account_addr = signer::address_of(account);
        
        // Initialize ownership
        initialize(account);
        
        // Verify owner
        assert!(owner(account_addr) == account_addr, 1);
        assert!(is_owner(account, account_addr), 2);
    }

    #[test(deployer = @0x123, initial_owner = @0x456)]
    public fun test_ownership_transfer(deployer: &signer, initial_owner: &signer) acquires OwnershipInfo {
        let deployer_addr = signer::address_of(deployer);
        let initial_owner_addr = signer::address_of(initial_owner);
        
        // Initialize with specific owner
        initialize_with_owner(deployer, initial_owner_addr);
        
        // Verify initial owner
        assert!(owner(deployer_addr) == initial_owner_addr, 1);
        
        // Transfer ownership back to deployer
        transfer_ownership(initial_owner, deployer_addr, deployer_addr);
        
        // Verify new owner
        assert!(owner(deployer_addr) == deployer_addr, 2);
    }

    #[test(account = @0x123)]
    public fun test_renounce_ownership(account: &signer) acquires OwnershipInfo {
        let account_addr = signer::address_of(account);
        
        // Initialize ownership
        initialize(account);
        
        // Renounce ownership
        renounce_ownership(account, account_addr);
        
        // Verify ownership renounced
        assert!(owner(account_addr) == @0x0, 1);
    }
} 