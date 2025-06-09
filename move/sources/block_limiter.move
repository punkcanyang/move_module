/// Move implementation of a block-based access limiting system
/// Provides rate limiting based on block height and time constraints
module block_limiter::block_limiter {
    use std::error;
    use std::signer;
    use aptos_framework::event;
    use aptos_std::smart_table::{Self, SmartTable};
    
    // Error codes
    const EACCESS_DENIED: u64 = 1;
    const ERATE_LIMITED: u64 = 2;
    const EALREADY_INITIALIZED: u64 = 3;
    const EUNAUTHORIZED: u64 = 4;
    const EINVALID_CONFIG: u64 = 5;

    // Events
    #[event]
    struct AccessRecorded has drop, store {
        account: address,
        block_height: u64,
        timestamp: u64,
    }

    #[event]
    struct AccessDenied has drop, store {
        account: address,
        reason: u8, // 1: block limit, 2: time limit, 3: cooldown
    }

    #[event]
    struct ConfigUpdated has drop, store {
        admin: address,
        max_accesses_per_block_window: u64,
        block_window_size: u64,
        max_accesses_per_time_window: u64,
        time_window_size: u64,
    }

    // Access record for each account
    struct AccessRecord has store, drop {
        last_access_block: u64,
        last_access_time: u64,
        access_count_in_window: u64,
        window_start_block: u64,
        window_start_time: u64,
    }

    // Block limiter configuration
    struct BlockLimiterConfig has key {
        max_accesses_per_block_window: u64,
        block_window_size: u64,
        max_accesses_per_time_window: u64,
        time_window_size: u64, // in microseconds
        block_cooldown: u64,
        time_cooldown: u64, // in microseconds
        admin: address,
        access_records: SmartTable<address, AccessRecord>,
    }

    // Initialize block limiter
    public fun initialize(
        admin: &signer,
        max_accesses_per_block_window: u64,
        block_window_size: u64,
        max_accesses_per_time_window: u64,
        time_window_size: u64,
        block_cooldown: u64,
        time_cooldown: u64
    ) {
        let admin_addr = signer::address_of(admin);
        assert!(!exists<BlockLimiterConfig>(admin_addr), error::already_exists(EALREADY_INITIALIZED));
        
        move_to(admin, BlockLimiterConfig {
            max_accesses_per_block_window,
            block_window_size,
            max_accesses_per_time_window,
            time_window_size,
            block_cooldown,
            time_cooldown,
            admin: admin_addr,
            access_records: smart_table::new<address, AccessRecord>(),
        });

        event::emit(ConfigUpdated {
            admin: admin_addr,
            max_accesses_per_block_window,
            block_window_size,
            max_accesses_per_time_window,
            time_window_size,
        });
    }

    // Check if access is allowed (without recording)
    public fun is_access_allowed(config_addr: address, account_addr: address): bool acquires BlockLimiterConfig {
        if (!exists<BlockLimiterConfig>(config_addr)) {
            return true // No limits if not configured
        };
        
        let config = borrow_global<BlockLimiterConfig>(config_addr);
        
        // Get current block height (simplified - in real implementation would use aptos_framework::block)
        let current_block = get_current_block_height();
        let current_time = get_current_time();
        
        if (!smart_table::contains(&config.access_records, account_addr)) {
            return true // First access is always allowed
        };
        
        let record = smart_table::borrow(&config.access_records, account_addr);
        
        // Check block-based cooldown
        if (current_block - record.last_access_block < config.block_cooldown) {
            return false
        };
        
        // Check time-based cooldown
        if (current_time - record.last_access_time < config.time_cooldown) {
            return false
        };
        
        // Check block window limits
        if (current_block - record.window_start_block >= config.block_window_size) {
            return true // New window, access allowed
        };
        
        if (record.access_count_in_window >= config.max_accesses_per_block_window) {
            return false
        };
        
        // Check time window limits
        if (current_time - record.window_start_time >= config.time_window_size) {
            return true // New time window, access allowed
        };
        
        if (record.access_count_in_window >= config.max_accesses_per_time_window) {
            return false
        };
        
        true
    }

    // Record access and update limits
    public fun record_access(account: &signer, config_addr: address) acquires BlockLimiterConfig {
        let account_addr = signer::address_of(account);
        
        assert!(exists<BlockLimiterConfig>(config_addr), error::not_found(EACCESS_DENIED));
        let config = borrow_global_mut<BlockLimiterConfig>(config_addr);
        
        let current_block = get_current_block_height();
        let current_time = get_current_time();
        
        if (!smart_table::contains(&config.access_records, account_addr)) {
            // First access
            smart_table::add(&mut config.access_records, account_addr, AccessRecord {
                last_access_block: current_block,
                last_access_time: current_time,
                access_count_in_window: 1,
                window_start_block: current_block,
                window_start_time: current_time,
            });
        } else {
            let record = smart_table::borrow_mut(&mut config.access_records, account_addr);
            
            // Check if we need to start a new window
            let new_block_window = current_block - record.window_start_block >= config.block_window_size;
            let new_time_window = current_time - record.window_start_time >= config.time_window_size;
            
            if (new_block_window || new_time_window) {
                // Start new window
                record.access_count_in_window = 1;
                record.window_start_block = current_block;
                record.window_start_time = current_time;
            } else {
                // Continue in current window
                record.access_count_in_window = record.access_count_in_window + 1;
            };
            
            record.last_access_block = current_block;
            record.last_access_time = current_time;
        };

        event::emit(AccessRecorded {
            account: account_addr,
            block_height: current_block,
            timestamp: current_time,
        });
    }

    // Require access (checks and records if allowed)
    public fun require_access(account: &signer, config_addr: address) acquires BlockLimiterConfig {
        let account_addr = signer::address_of(account);
        
        assert!(is_access_allowed(config_addr, account_addr), error::permission_denied(ERATE_LIMITED));
        record_access(account, config_addr);
    }

    // Check access status without side effects
    public fun check_access(config_addr: address, account_addr: address): bool acquires BlockLimiterConfig {
        is_access_allowed(config_addr, account_addr)
    }

    // Get access record for an account
    public fun get_access_record(config_addr: address, account_addr: address): (u64, u64, u64, u64, u64) acquires BlockLimiterConfig {
        let config = borrow_global<BlockLimiterConfig>(config_addr);
        
        if (!smart_table::contains(&config.access_records, account_addr)) {
            return (0, 0, 0, 0, 0)
        };
        
        let record = smart_table::borrow(&config.access_records, account_addr);
        (record.last_access_block, record.last_access_time, record.access_count_in_window,
         record.window_start_block, record.window_start_time)
    }

    // Update block limits (admin only)
    public fun update_block_limits(
        admin: &signer,
        config_addr: address,
        max_accesses_per_block_window: u64,
        block_window_size: u64,
        block_cooldown: u64
    ) acquires BlockLimiterConfig {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<BlockLimiterConfig>(config_addr);
        
        assert!(config.admin == admin_addr, error::permission_denied(EUNAUTHORIZED));
        
        config.max_accesses_per_block_window = max_accesses_per_block_window;
        config.block_window_size = block_window_size;
        config.block_cooldown = block_cooldown;
    }

    // Update time limits (admin only)
    public fun update_time_limits(
        admin: &signer,
        config_addr: address,
        max_accesses_per_time_window: u64,
        time_window_size: u64,
        time_cooldown: u64
    ) acquires BlockLimiterConfig {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<BlockLimiterConfig>(config_addr);
        
        assert!(config.admin == admin_addr, error::permission_denied(EUNAUTHORIZED));
        
        config.max_accesses_per_time_window = max_accesses_per_time_window;
        config.time_window_size = time_window_size;
        config.time_cooldown = time_cooldown;
    }

    // Reset access record for an account (admin only)
    public fun reset_access_record(admin: &signer, config_addr: address, account_addr: address) acquires BlockLimiterConfig {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<BlockLimiterConfig>(config_addr);
        
        assert!(config.admin == admin_addr, error::permission_denied(EUNAUTHORIZED));
        
        if (smart_table::contains(&config.access_records, account_addr)) {
            smart_table::remove(&mut config.access_records, account_addr);
        };
    }

    // Get configuration
    public fun get_config(config_addr: address): (u64, u64, u64, u64, u64, u64, address) acquires BlockLimiterConfig {
        let config = borrow_global<BlockLimiterConfig>(config_addr);
        (config.max_accesses_per_block_window, config.block_window_size,
         config.max_accesses_per_time_window, config.time_window_size,
         config.block_cooldown, config.time_cooldown, config.admin)
    }

    // Helper functions (placeholders for actual implementations)
    fun get_current_block_height(): u64 {
        // In real implementation, use aptos_framework::block::get_current_block_height()
        // For testing, return a mock value
        1000
    }

    fun get_current_time(): u64 {
        // In real implementation, use aptos_framework::timestamp::now_microseconds()
        // For testing, return a mock value
        1000000
    }

    #[test(admin = @0x123, user = @0x456)]
    public fun test_basic_limiting(admin: &signer, user: &signer) acquires BlockLimiterConfig {
        let admin_addr = signer::address_of(admin);
        let _user_addr = signer::address_of(user);
        
        // Initialize with very restrictive limits for testing
        initialize(admin, 1, 10, 1, 60, 5, 30);
        
        // Test configuration retrieval
        let (max_block, window_block, _max_time, _window_time, _cooldown_block, _cooldown_time, _config_admin) = get_config(admin_addr);
        assert!(max_block == 1, 1);
        assert!(window_block == 10, 2);
        assert!(_config_admin == admin_addr, 3);
    }

    #[test(admin = @0x123)]
    public fun test_config_updates(admin: &signer) acquires BlockLimiterConfig {
        let admin_addr = signer::address_of(admin);
        
        // Initialize
        initialize(admin, 10, 100, 5, 300, 1, 10);
        
        // Update block limits
        let (max_block, window_block, _max_time, _window_time, _cooldown_block, _cooldown_time, _config_admin) = get_config(admin_addr);
        assert!(max_block == 10, 1);
        
        // Update limits
        update_block_limits(admin, admin_addr, 20, 200, 2);
        
        // Verify update
        let (max_block2, window_block2, _max_time2, _window_time2, _cooldown_block2, _cooldown_time2, _config_admin2) = get_config(admin_addr);
        assert!(max_block2 == 20, 2);
        assert!(window_block2 == 200, 3);
    }
} 