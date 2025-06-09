/// Move implementation of OpenZeppelin's Pausable contract
/// Provides emergency stop mechanism that can be triggered by authorized accounts
module pausable::pausable {
    use std::error;
    use std::signer;
    use aptos_framework::event;
    
    // Error codes
    const EENFORCED_PAUSE: u64 = 1;
    const EEXPECTED_PAUSE: u64 = 2;
    const EALREADY_INITIALIZED: u64 = 3;

    // Events
    #[event]
    struct Paused has drop, store {
        account: address,
    }

    #[event]
    struct Unpaused has drop, store {
        account: address,
    }

    // Pausable state resource
    struct PausableState has key {
        paused: bool,
    }

    // Initialize pausable state (unpaused by default)
    public fun initialize(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<PausableState>(account_addr), error::already_exists(EALREADY_INITIALIZED));
        
        move_to(account, PausableState {
            paused: false,
        });
    }

    // Check if the contract is paused
    public fun is_paused(contract_addr: address): bool acquires PausableState {
        if (!exists<PausableState>(contract_addr)) {
            return false
        };
        
        borrow_global<PausableState>(contract_addr).paused
    }

    // Assert that the contract is not paused
    public fun require_not_paused(contract_addr: address) acquires PausableState {
        assert!(!is_paused(contract_addr), error::unavailable(EENFORCED_PAUSE));
    }

    // Assert that the contract is paused
    public fun require_paused(contract_addr: address) acquires PausableState {
        assert!(is_paused(contract_addr), error::invalid_state(EEXPECTED_PAUSE));
    }

    // Pause the contract (internal function)
    public fun pause(pauser: &signer, contract_addr: address) acquires PausableState {
        require_not_paused(contract_addr);
        
        let pausable_state = borrow_global_mut<PausableState>(contract_addr);
        pausable_state.paused = true;
        
        event::emit(Paused {
            account: signer::address_of(pauser),
        });
    }

    // Unpause the contract (internal function)
    public fun unpause(pauser: &signer, contract_addr: address) acquires PausableState {
        require_paused(contract_addr);
        
        let pausable_state = borrow_global_mut<PausableState>(contract_addr);
        pausable_state.paused = false;
        
        event::emit(Unpaused {
            account: signer::address_of(pauser),
        });
    }

    // Modifier-like function to ensure operation is only called when not paused
    public fun when_not_paused(contract_addr: address) acquires PausableState {
        require_not_paused(contract_addr);
    }

    // Modifier-like function to ensure operation is only called when paused
    public fun when_paused(contract_addr: address) acquires PausableState {
        require_paused(contract_addr);
    }

    // Emergency pause function (can be combined with access control)
    public fun emergency_pause(emergency_pauser: &signer, contract_addr: address) acquires PausableState {
        pause(emergency_pauser, contract_addr);
    }

    // Emergency unpause function (can be combined with access control)
    public fun emergency_unpause(emergency_pauser: &signer, contract_addr: address) acquires PausableState {
        unpause(emergency_pauser, contract_addr);
    }

    #[test(account = @0x123)]
    public fun test_pausable_functionality(account: &signer) acquires PausableState {
        let account_addr = signer::address_of(account);
        
        // Initialize pausable state
        initialize(account);
        
        // Verify initial state is not paused
        assert!(!is_paused(account_addr), 1);
        
        // Pause the contract
        pause(account, account_addr);
        
        // Verify contract is paused
        assert!(is_paused(account_addr), 2);
        
        // Unpause the contract
        unpause(account, account_addr);
        
        // Verify contract is not paused
        assert!(!is_paused(account_addr), 3);
    }

    #[test(account = @0x123)]
    #[expected_failure(abort_code = 851969, location = Self)]
    public fun test_require_not_paused_when_paused(account: &signer) acquires PausableState {
        let account_addr = signer::address_of(account);
        
        // Initialize and pause
        initialize(account);
        pause(account, account_addr);
        
        // This should fail
        require_not_paused(account_addr);
    }

    #[test(account = @0x123)]
    #[expected_failure(abort_code = 196610, location = Self)]
    public fun test_require_paused_when_not_paused(account: &signer) acquires PausableState {
        let account_addr = signer::address_of(account);
        
        // Initialize (not paused by default)
        initialize(account);
        
        // This should fail
        require_paused(account_addr);
    }

    #[test(account = @0x123)]
    #[expected_failure(abort_code = 851969, location = Self)]
    public fun test_double_pause(account: &signer) acquires PausableState {
        let account_addr = signer::address_of(account);
        
        // Initialize and pause
        initialize(account);
        pause(account, account_addr);
        
        // Try to pause again - should fail
        pause(account, account_addr);
    }

    #[test(account = @0x123)]
    #[expected_failure(abort_code = 196610, location = Self)]
    public fun test_double_unpause(account: &signer) acquires PausableState {
        let account_addr = signer::address_of(account);
        
        // Initialize (not paused by default)
        initialize(account);
        
        // Try to unpause when not paused - should fail
        unpause(account, account_addr);
    }
} 