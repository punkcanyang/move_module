/// Move implementation of OpenZeppelin's AccessControl contract
/// Provides role-based access control mechanisms
module access_control::access_control {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::event;
    use aptos_std::smart_table::{Self, SmartTable};
    
    // Error codes
    const EUNAUTHORIZED: u64 = 1;
    const EROLE_NOT_FOUND: u64 = 2;
    const EALREADY_INITIALIZED: u64 = 3;
    const EBAD_CONFIRMATION: u64 = 4;

    // Constants
    const DEFAULT_ADMIN_ROLE: vector<u8> = b"DEFAULT_ADMIN_ROLE";

    // Events
    #[event]
    struct RoleGranted has drop, store {
        role: String,
        account: address,
        sender: address,
    }

    #[event]
    struct RoleRevoked has drop, store {
        role: String,
        account: address,
        sender: address,
    }

    // Access control info resource
    struct AccessControlInfo has key {
        roles: SmartTable<String, RoleData>,
    }

    // Role data structure
    struct RoleData has store {
        members: SmartTable<address, bool>,
        admin_role: String,
    }

    // Initialize access control with DEFAULT_ADMIN_ROLE granted to deployer
    public fun initialize(deployer: &signer) {
        let deployer_addr = signer::address_of(deployer);
        assert!(!exists<AccessControlInfo>(deployer_addr), error::already_exists(EALREADY_INITIALIZED));
        
        let roles = smart_table::new<String, RoleData>();
        let default_admin_role = string::utf8(DEFAULT_ADMIN_ROLE);
        
        // Create default admin role
        let admin_members = smart_table::new<address, bool>();
        smart_table::add(&mut admin_members, deployer_addr, true);
        
        let admin_role_data = RoleData {
            members: admin_members,
            admin_role: default_admin_role,
        };
        
        smart_table::add(&mut roles, default_admin_role, admin_role_data);
        
        move_to(deployer, AccessControlInfo {
            roles,
        });

        event::emit(RoleGranted {
            role: default_admin_role,
            account: deployer_addr,
            sender: deployer_addr,
        });
    }

    // Check if an account has a specific role
    public fun has_role(contract_addr: address, role: String, account: address): bool acquires AccessControlInfo {
        if (!exists<AccessControlInfo>(contract_addr)) {
            return false
        };
        
        let access_control = borrow_global<AccessControlInfo>(contract_addr);
        if (!smart_table::contains(&access_control.roles, role)) {
            return false
        };
        
        let role_data = smart_table::borrow(&access_control.roles, role);
        if (!smart_table::contains(&role_data.members, account)) {
            return false
        };
        
        *smart_table::borrow(&role_data.members, account)
    }

    // Get the admin role for a given role
    public fun get_role_admin(contract_addr: address, role: String): String acquires AccessControlInfo {
        let access_control = borrow_global<AccessControlInfo>(contract_addr);
        if (!smart_table::contains(&access_control.roles, role)) {
            return string::utf8(DEFAULT_ADMIN_ROLE)
        };
        
        let role_data = smart_table::borrow(&access_control.roles, role);
        role_data.admin_role
    }

    // Grant a role to an account
    public fun grant_role(admin: &signer, contract_addr: address, role: String, account: address) acquires AccessControlInfo {
        let admin_addr = signer::address_of(admin);
        let admin_role = get_role_admin(contract_addr, role);
        
        // Check if caller has admin role for this role
        assert!(has_role(contract_addr, admin_role, admin_addr), error::permission_denied(EUNAUTHORIZED));
        
        let access_control = borrow_global_mut<AccessControlInfo>(contract_addr);
        
        // Create role if it doesn't exist
        if (!smart_table::contains(&access_control.roles, role)) {
            let members = smart_table::new<address, bool>();
            let role_data = RoleData {
                members,
                admin_role: string::utf8(DEFAULT_ADMIN_ROLE),
            };
            smart_table::add(&mut access_control.roles, role, role_data);
        };
        
        let role_data = smart_table::borrow_mut(&mut access_control.roles, role);
        
        // Grant role if not already granted
        if (!smart_table::contains(&role_data.members, account)) {
            smart_table::add(&mut role_data.members, account, true);
            
            event::emit(RoleGranted {
                role,
                account,
                sender: admin_addr,
            });
        } else {
            // Update existing entry
            let member_ref = smart_table::borrow_mut(&mut role_data.members, account);
            if (!*member_ref) {
                *member_ref = true;
                
                event::emit(RoleGranted {
                    role,
                    account,
                    sender: admin_addr,
                });
            };
        };
    }

    // Revoke a role from an account
    public fun revoke_role(admin: &signer, contract_addr: address, role: String, account: address) acquires AccessControlInfo {
        let admin_addr = signer::address_of(admin);
        let admin_role = get_role_admin(contract_addr, role);
        
        // Check if caller has admin role for this role
        assert!(has_role(contract_addr, admin_role, admin_addr), error::permission_denied(EUNAUTHORIZED));
        
        let access_control = borrow_global_mut<AccessControlInfo>(contract_addr);
        
        if (smart_table::contains(&access_control.roles, role)) {
            let role_data = smart_table::borrow_mut(&mut access_control.roles, role);
            
            if (smart_table::contains(&role_data.members, account)) {
                let member_ref = smart_table::borrow_mut(&mut role_data.members, account);
                if (*member_ref) {
                    *member_ref = false;
                    
                    event::emit(RoleRevoked {
                        role,
                        account,
                        sender: admin_addr,
                    });
                };
            };
        };
    }

    // Renounce a role (caller must confirm their address)
    public fun renounce_role(caller: &signer, contract_addr: address, role: String, caller_confirmation: address) acquires AccessControlInfo {
        let caller_addr = signer::address_of(caller);
        assert!(caller_addr == caller_confirmation, error::invalid_argument(EBAD_CONFIRMATION));
        
        let access_control = borrow_global_mut<AccessControlInfo>(contract_addr);
        
        if (smart_table::contains(&access_control.roles, role)) {
            let role_data = smart_table::borrow_mut(&mut access_control.roles, role);
            
            if (smart_table::contains(&role_data.members, caller_addr)) {
                let member_ref = smart_table::borrow_mut(&mut role_data.members, caller_addr);
                if (*member_ref) {
                    *member_ref = false;
                    
                    event::emit(RoleRevoked {
                        role,
                        account: caller_addr,
                        sender: caller_addr,
                    });
                };
            };
        };
    }

    // Helper function for modifier-like behavior
    public fun only_role(caller: &signer, contract_addr: address, role: String) acquires AccessControlInfo {
        let caller_addr = signer::address_of(caller);
        assert!(has_role(contract_addr, role, caller_addr), error::permission_denied(EUNAUTHORIZED));
    }

    // Get default admin role string
    public fun default_admin_role(): String {
        string::utf8(DEFAULT_ADMIN_ROLE)
    }

    #[test(deployer = @0x123, user = @0x456)]
    public fun test_role_management(deployer: &signer, user: &signer) acquires AccessControlInfo {
        let deployer_addr = signer::address_of(deployer);
        let user_addr = signer::address_of(user);
        let test_role = string::utf8(b"TEST_ROLE");
        
        // Initialize access control
        initialize(deployer);
        
        // Verify deployer has default admin role
        assert!(has_role(deployer_addr, default_admin_role(), deployer_addr), 1);
        
        // Grant test role to user
        grant_role(deployer, deployer_addr, test_role, user_addr);
        assert!(has_role(deployer_addr, test_role, user_addr), 2);
        
        // Revoke test role from user
        revoke_role(deployer, deployer_addr, test_role, user_addr);
        assert!(!has_role(deployer_addr, test_role, user_addr), 3);
    }

    #[test(deployer = @0x123, user = @0x456)]
    public fun test_role_renounce(deployer: &signer, user: &signer) acquires AccessControlInfo {
        let deployer_addr = signer::address_of(deployer);
        let user_addr = signer::address_of(user);
        let test_role = string::utf8(b"TEST_ROLE");
        
        // Initialize access control
        initialize(deployer);
        
        // Grant test role to user
        grant_role(deployer, deployer_addr, test_role, user_addr);
        assert!(has_role(deployer_addr, test_role, user_addr), 1);
        
        // User renounces their own role
        renounce_role(user, deployer_addr, test_role, user_addr);
        assert!(!has_role(deployer_addr, test_role, user_addr), 2);
    }
} 