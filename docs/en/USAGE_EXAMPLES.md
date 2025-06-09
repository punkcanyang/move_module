# 🚀 OpenZeppelin Move Usage Examples

This document provides comprehensive usage examples for all modules in the OpenZeppelin Move security suite across various blockchain application scenarios.

## Table of Contents

1. [Basic Usage Examples](#basic-usage-examples)
2. [DeFi Application Examples](#defi-application-examples)
3. [NFT Platform Examples](#nft-platform-examples)
4. [Gaming Application Examples](#gaming-application-examples)
5. [DAO Governance Examples](#dao-governance-examples)
6. [Advanced Integration Patterns](#advanced-integration-patterns)

---

## Basic Usage Examples

### Simple Owned Contract

```move
module example::simple_owned {
    use std::signer;
    use move_security::ownable;

    public entry fun initialize(owner: &signer) {
        ownable::initialize_ownership(owner);
    }

    public entry fun admin_only_function(caller: &signer) {
        let caller_addr = signer::address_of(caller);
        ownable::require_owner(caller_addr);
        
        // Admin-only logic here
    }

    public entry fun transfer_ownership_to(
        current_owner: &signer,
        new_owner_addr: address
    ) {
        ownable::transfer_ownership(current_owner, new_owner_addr);
    }
}
```

### Role-Based Access Control

```move
module example::rbac_system {
    use std::signer;
    use move_security::access_control;

    const MINTER_ROLE: vector<u8> = b"MINTER_ROLE";
    const BURNER_ROLE: vector<u8> = b"BURNER_ROLE";

    public entry fun initialize(admin: &signer) {
        access_control::initialize_access_control(admin);
        
        // Setup custom roles
        let admin_addr = signer::address_of(admin);
        access_control::setup_role(admin, MINTER_ROLE, access_control::default_admin_role());
        access_control::setup_role(admin, BURNER_ROLE, access_control::default_admin_role());
    }

    public entry fun mint_tokens(minter: &signer, to: address, amount: u64) {
        let minter_addr = signer::address_of(minter);
        assert!(access_control::has_role(minter_addr, MINTER_ROLE), 1);
        
        // Minting logic here
    }

    public entry fun burn_tokens(burner: &signer, amount: u64) {
        let burner_addr = signer::address_of(burner);
        assert!(access_control::has_role(burner_addr, BURNER_ROLE), 2);
        
        // Burning logic here
    }
}
```

### Emergency Pausable Contract

```move
module example::pausable_service {
    use std::signer;
    use move_security::pausable;
    use move_security::ownable;

    public entry fun initialize(owner: &signer) {
        ownable::initialize_ownership(owner);
        pausable::initialize_pausable(owner);
    }

    public entry fun critical_operation(user: &signer) {
        let user_addr = signer::address_of(user);
        pausable::when_not_paused(user_addr);
        
        // Critical business logic here
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

---

## DeFi Application Examples

### Decentralized Exchange (DEX)

```move
module defi::dex_platform {
    use std::signer;
    use aptos_framework::coin;
    use move_security::ownable;
    use move_security::pausable;
    use move_security::block_limiter;
    use move_security::access_control;

    const LIQUIDITY_PROVIDER_ROLE: vector<u8> = b"LIQUIDITY_PROVIDER";
    const FEE_MANAGER_ROLE: vector<u8> = b"FEE_MANAGER";

    struct TradingPair<phantom X, phantom Y> has key {
        reserve_x: u64,
        reserve_y: u64,
        fee_rate: u64,
    }

    public entry fun initialize_dex(admin: &signer) {
        // Initialize all security modules
        ownable::initialize_ownership(admin);
        pausable::initialize_pausable(admin);
        access_control::initialize_access_control(admin);
        
        // Rate limiting: max 10 trades per block, 1000 per hour
        block_limiter::initialize_block_limiter(admin, 10, 1000, 10000);
        
        // Setup roles
        access_control::setup_role(admin, LIQUIDITY_PROVIDER_ROLE, access_control::default_admin_role());
        access_control::setup_role(admin, FEE_MANAGER_ROLE, access_control::default_admin_role());
    }

    public entry fun add_liquidity<X, Y>(
        provider: &signer,
        amount_x: u64,
        amount_y: u64
    ) {
        let provider_addr = signer::address_of(provider);
        
        // Security checks
        pausable::when_not_paused(provider_addr);
        assert!(access_control::has_role(provider_addr, LIQUIDITY_PROVIDER_ROLE), 1);
        
        // Rate limiting
        block_limiter::check_and_update_limits(provider_addr);
        
        // Liquidity provision logic here
    }

    public entry fun swap<X, Y>(
        trader: &signer,
        amount_in: u64,
        min_amount_out: u64
    ) {
        let trader_addr = signer::address_of(trader);
        
        // Security checks
        pausable::when_not_paused(trader_addr);
        block_limiter::check_and_update_limits(trader_addr);
        
        // Swap execution logic here
    }

    public entry fun update_fee_rate<X, Y>(
        fee_manager: &signer,
        new_fee_rate: u64
    ) acquires TradingPair {
        let manager_addr = signer::address_of(fee_manager);
        assert!(access_control::has_role(manager_addr, FEE_MANAGER_ROLE), 2);
        
        let pair = borrow_global_mut<TradingPair<X, Y>>(@defi);
        pair.fee_rate = new_fee_rate;
    }
}
```

### Lending Protocol

```move
module defi::lending_protocol {
    use std::signer;
    use move_security::ownable;
    use move_security::pausable;
    use move_security::access_control;
    use move_security::capability_store;

    const LIQUIDATOR_ROLE: vector<u8> = b"LIQUIDATOR";
    const ORACLE_ROLE: vector<u8> = b"ORACLE";

    struct LendingPool<phantom T> has key {
        total_supply: u64,
        total_borrow: u64,
        interest_rate: u64,
        collateral_factor: u64,
    }

    struct LiquidationCapability has store {}

    public entry fun initialize_lending(admin: &signer) {
        ownable::initialize_ownership(admin);
        pausable::initialize_pausable(admin);
        access_control::initialize_access_control(admin);
        capability_store::initialize_store<LiquidationCapability>(admin);
        
        // Setup roles
        access_control::setup_role(admin, LIQUIDATOR_ROLE, access_control::default_admin_role());
        access_control::setup_role(admin, ORACLE_ROLE, access_control::default_admin_role());
        
        // Store liquidation capability
        let liquidation_cap = LiquidationCapability {};
        capability_store::store_capability(admin, liquidation_cap);
    }

    public entry fun supply<T>(
        supplier: &signer,
        amount: u64
    ) {
        let supplier_addr = signer::address_of(supplier);
        pausable::when_not_paused(supplier_addr);
        
        // Supply logic here
    }

    public entry fun borrow<T>(
        borrower: &signer,
        amount: u64
    ) {
        let borrower_addr = signer::address_of(borrower);
        pausable::when_not_paused(borrower_addr);
        
        // Borrow logic here
    }

    public entry fun liquidate<T>(
        liquidator: &signer,
        borrower_addr: address,
        repay_amount: u64
    ) {
        let liquidator_addr = signer::address_of(liquidator);
        assert!(access_control::has_role(liquidator_addr, LIQUIDATOR_ROLE), 1);
        
        // Extract liquidation capability
        let _liquidation_cap = capability_store::extract_capability<LiquidationCapability>(liquidator);
        
        // Liquidation logic here
        
        // Store capability back
        capability_store::store_capability(liquidator, _liquidation_cap);
    }
}
```

---

## NFT Platform Examples

### NFT Marketplace

```move
module nft::marketplace {
    use std::signer;
    use std::string::String;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use move_security::ownable;
    use move_security::pausable;
    use move_security::access_control;

    const CURATOR_ROLE: vector<u8> = b"CURATOR";
    const VERIFIED_CREATOR_ROLE: vector<u8> = b"VERIFIED_CREATOR";

    struct NFTListing has store {
        creator: address,
        price: u64,
        is_verified: bool,
        metadata_uri: String,
    }

    struct Marketplace has key {
        listings: vector<NFTListing>,
        platform_fee: u64,
        total_volume: u64,
    }

    public entry fun initialize_marketplace(admin: &signer) {
        ownable::initialize_ownership(admin);
        pausable::initialize_pausable(admin);
        access_control::initialize_access_control(admin);
        
        // Setup marketplace roles
        access_control::setup_role(admin, CURATOR_ROLE, access_control::default_admin_role());
        access_control::setup_role(admin, VERIFIED_CREATOR_ROLE, access_control::default_admin_role());
        
        // Initialize marketplace
        let marketplace = Marketplace {
            listings: vector::empty(),
            platform_fee: 250, // 2.5%
            total_volume: 0,
        };
        move_to(admin, marketplace);
    }

    public entry fun create_and_list_nft(
        creator: &signer,
        metadata_uri: String,
        price: u64
    ) acquires Marketplace {
        let creator_addr = signer::address_of(creator);
        pausable::when_not_paused(creator_addr);
        
        let is_verified = access_control::has_role(creator_addr, VERIFIED_CREATOR_ROLE);
        
        let listing = NFTListing {
            creator: creator_addr,
            price,
            is_verified,
            metadata_uri,
        };
        
        let marketplace = borrow_global_mut<Marketplace>(@nft);
        vector::push_back(&mut marketplace.listings, listing);
    }

    public entry fun purchase_nft(
        buyer: &signer,
        listing_index: u64
    ) acquires Marketplace {
        let buyer_addr = signer::address_of(buyer);
        pausable::when_not_paused(buyer_addr);
        
        let marketplace = borrow_global_mut<Marketplace>(@nft);
        let listing = vector::borrow(&marketplace.listings, listing_index);
        
        // Transfer payment
        coin::transfer<AptosCoin>(buyer, listing.creator, listing.price);
        
        // Update volume
        marketplace.total_volume = marketplace.total_volume + listing.price;
        
        // Remove listing (simplified)
        vector::remove(&mut marketplace.listings, listing_index);
    }

    public entry fun verify_creator(
        curator: &signer,
        creator_addr: address
    ) {
        let curator_addr = signer::address_of(curator);
        assert!(access_control::has_role(curator_addr, CURATOR_ROLE), 1);
        
        access_control::grant_role(curator, VERIFIED_CREATOR_ROLE, creator_addr);
    }
}
```

### NFT Collection with Royalties

```move
module nft::royalty_collection {
    use std::signer;
    use std::string::String;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::capability_store;

    const MINTER_ROLE: vector<u8> = b"MINTER";

    struct MintingCapability has store {}
    
    struct RoyaltyInfo has store {
        recipient: address,
        percentage: u64, // Basis points (10000 = 100%)
    }

    struct Collection has key {
        name: String,
        symbol: String,
        max_supply: u64,
        current_supply: u64,
        royalty_info: RoyaltyInfo,
    }

    public entry fun create_collection(
        creator: &signer,
        name: String,
        symbol: String,
        max_supply: u64,
        royalty_percentage: u64
    ) {
        ownable::initialize_ownership(creator);
        access_control::initialize_access_control(creator);
        capability_store::initialize_store<MintingCapability>(creator);
        
        let creator_addr = signer::address_of(creator);
        
        // Setup minter role
        access_control::setup_role(creator, MINTER_ROLE, access_control::default_admin_role());
        access_control::grant_role(creator, MINTER_ROLE, creator_addr);
        
        // Store minting capability
        let mint_cap = MintingCapability {};
        capability_store::store_capability(creator, mint_cap);
        
        // Create collection
        let collection = Collection {
            name,
            symbol,
            max_supply,
            current_supply: 0,
            royalty_info: RoyaltyInfo {
                recipient: creator_addr,
                percentage: royalty_percentage,
            },
        };
        move_to(creator, collection);
    }

    public entry fun mint_nft(
        minter: &signer,
        to: address,
        token_uri: String
    ) acquires Collection {
        let minter_addr = signer::address_of(minter);
        assert!(access_control::has_role(minter_addr, MINTER_ROLE), 1);
        
        // Extract minting capability
        let _mint_cap = capability_store::extract_capability<MintingCapability>(minter);
        
        let collection = borrow_global_mut<Collection>(minter_addr);
        assert!(collection.current_supply < collection.max_supply, 2);
        
        // Mint logic here
        collection.current_supply = collection.current_supply + 1;
        
        // Store capability back
        capability_store::store_capability(minter, _mint_cap);
    }

    public entry fun update_royalty(
        owner: &signer,
        new_recipient: address,
        new_percentage: u64
    ) acquires Collection {
        let owner_addr = signer::address_of(owner);
        ownable::require_owner(owner_addr);
        
        let collection = borrow_global_mut<Collection>(owner_addr);
        collection.royalty_info = RoyaltyInfo {
            recipient: new_recipient,
            percentage: new_percentage,
        };
    }
}
```

---

## Gaming Application Examples

### Game Items and Economy

```move
module gaming::rpg_items {
    use std::signer;
    use std::string::String;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::pausable;
    use move_security::block_limiter;

    const GAME_MASTER_ROLE: vector<u8> = b"GAME_MASTER";
    const PLAYER_ROLE: vector<u8> = b"PLAYER";

    struct GameItem has store {
        id: u64,
        name: String,
        rarity: u8,
        power: u64,
        durability: u64,
    }

    struct PlayerInventory has key {
        items: vector<GameItem>,
        gold: u64,
        experience: u64,
    }

    public entry fun initialize_game(admin: &signer) {
        ownable::initialize_ownership(admin);
        pausable::initialize_pausable(admin);
        access_control::initialize_access_control(admin);
        
        // Rate limiting for actions
        block_limiter::initialize_block_limiter(admin, 5, 100, 1000);
        
        // Setup game roles
        access_control::setup_role(admin, GAME_MASTER_ROLE, access_control::default_admin_role());
        access_control::setup_role(admin, PLAYER_ROLE, access_control::default_admin_role());
    }

    public entry fun create_player(player: &signer) {
        let player_addr = signer::address_of(player);
        
        // Auto-grant player role
        // In real implementation, this might require approval
        
        let inventory = PlayerInventory {
            items: vector::empty(),
            gold: 100, // Starting gold
            experience: 0,
        };
        move_to(player, inventory);
    }

    public entry fun spawn_item(
        game_master: &signer,
        player_addr: address,
        item_id: u64,
        name: String,
        rarity: u8,
        power: u64
    ) acquires PlayerInventory {
        let gm_addr = signer::address_of(game_master);
        assert!(access_control::has_role(gm_addr, GAME_MASTER_ROLE), 1);
        pausable::when_not_paused(gm_addr);
        
        let item = GameItem {
            id: item_id,
            name,
            rarity,
            power,
            durability: 100,
        };
        
        let inventory = borrow_global_mut<PlayerInventory>(player_addr);
        vector::push_back(&mut inventory.items, item);
    }

    public entry fun use_item(
        player: &signer,
        item_index: u64
    ) acquires PlayerInventory {
        let player_addr = signer::address_of(player);
        pausable::when_not_paused(player_addr);
        block_limiter::check_and_update_limits(player_addr);
        
        let inventory = borrow_global_mut<PlayerInventory>(player_addr);
        let item = vector::borrow_mut(&mut inventory.items, item_index);
        
        // Use item logic
        item.durability = if (item.durability > 10) {
            item.durability - 10
        } else {
            0
        };
        
        // Remove item if durability is 0
        if (item.durability == 0) {
            vector::remove(&mut inventory.items, item_index);
        };
    }

    public entry fun emergency_maintenance(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        ownable::require_owner(admin_addr);
        pausable::pause(admin);
    }
}
```

### Tournament System

```move
module gaming::tournament {
    use std::signer;
    use std::vector;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::capability_store;

    const TOURNAMENT_ORGANIZER_ROLE: vector<u8> = b"TOURNAMENT_ORGANIZER";
    
    struct TournamentCapability has store {}

    struct Tournament has key {
        name: vector<u8>,
        participants: vector<address>,
        prize_pool: u64,
        max_participants: u64,
        is_active: bool,
        winner: Option<address>,
    }

    public entry fun initialize_tournament_system(admin: &signer) {
        ownable::initialize_ownership(admin);
        access_control::initialize_access_control(admin);
        capability_store::initialize_store<TournamentCapability>(admin);
        
        // Setup tournament organizer role
        access_control::setup_role(admin, TOURNAMENT_ORGANIZER_ROLE, access_control::default_admin_role());
        
        // Store tournament capability
        let tournament_cap = TournamentCapability {};
        capability_store::store_capability(admin, tournament_cap);
    }

    public entry fun create_tournament(
        organizer: &signer,
        name: vector<u8>,
        max_participants: u64,
        prize_pool: u64
    ) {
        let organizer_addr = signer::address_of(organizer);
        assert!(access_control::has_role(organizer_addr, TOURNAMENT_ORGANIZER_ROLE), 1);
        
        // Extract tournament capability
        let _tournament_cap = capability_store::extract_capability<TournamentCapability>(organizer);
        
        let tournament = Tournament {
            name,
            participants: vector::empty(),
            prize_pool,
            max_participants,
            is_active: true,
            winner: option::none(),
        };
        move_to(organizer, tournament);
        
        // Store capability back
        capability_store::store_capability(organizer, _tournament_cap);
    }

    public entry fun join_tournament(
        player: &signer,
        tournament_addr: address
    ) acquires Tournament {
        let tournament = borrow_global_mut<Tournament>(tournament_addr);
        assert!(tournament.is_active, 2);
        assert!(vector::length(&tournament.participants) < tournament.max_participants, 3);
        
        let player_addr = signer::address_of(player);
        vector::push_back(&mut tournament.participants, player_addr);
    }

    public entry fun end_tournament(
        organizer: &signer,
        winner_addr: address
    ) acquires Tournament {
        let organizer_addr = signer::address_of(organizer);
        assert!(access_control::has_role(organizer_addr, TOURNAMENT_ORGANIZER_ROLE), 1);
        
        let tournament = borrow_global_mut<Tournament>(organizer_addr);
        tournament.is_active = false;
        tournament.winner = option::some(winner_addr);
        
        // Distribute prizes logic here
    }
}
```

---

## DAO Governance Examples

### Governance Token and Proposals

```move
module dao::governance {
    use std::signer;
    use std::string::String;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::pausable;

    const PROPOSER_ROLE: vector<u8> = b"PROPOSER";
    const EXECUTOR_ROLE: vector<u8> = b"EXECUTOR";

    struct Proposal has store {
        id: u64,
        title: String,
        description: String,
        proposer: address,
        votes_for: u64,
        votes_against: u64,
        status: u8, // 0: Active, 1: Passed, 2: Rejected, 3: Executed
        created_at: u64,
        voting_end: u64,
    }

    struct GovernanceToken has key {
        total_supply: u64,
        balances: vector<u64>,
        holders: vector<address>,
    }

    struct DAO has key {
        proposals: vector<Proposal>,
        next_proposal_id: u64,
        voting_period: u64,
        quorum_threshold: u64,
    }

    public entry fun initialize_dao(
        founder: &signer,
        voting_period: u64,
        quorum_threshold: u64
    ) {
        ownable::initialize_ownership(founder);
        access_control::initialize_access_control(founder);
        pausable::initialize_pausable(founder);
        
        // Setup governance roles
        access_control::setup_role(founder, PROPOSER_ROLE, access_control::default_admin_role());
        access_control::setup_role(founder, EXECUTOR_ROLE, access_control::default_admin_role());
        
        // Initialize DAO
        let dao = DAO {
            proposals: vector::empty(),
            next_proposal_id: 1,
            voting_period,
            quorum_threshold,
        };
        move_to(founder, dao);
        
        // Initialize governance token
        let token = GovernanceToken {
            total_supply: 1000000,
            balances: vector::empty(),
            holders: vector::empty(),
        };
        move_to(founder, token);
    }

    public entry fun create_proposal(
        proposer: &signer,
        title: String,
        description: String
    ) acquires DAO {
        let proposer_addr = signer::address_of(proposer);
        assert!(access_control::has_role(proposer_addr, PROPOSER_ROLE), 1);
        pausable::when_not_paused(proposer_addr);
        
        let dao = borrow_global_mut<DAO>(@dao);
        let proposal = Proposal {
            id: dao.next_proposal_id,
            title,
            description,
            proposer: proposer_addr,
            votes_for: 0,
            votes_against: 0,
            status: 0, // Active
            created_at: aptos_framework::timestamp::now_seconds(),
            voting_end: aptos_framework::timestamp::now_seconds() + dao.voting_period,
        };
        
        vector::push_back(&mut dao.proposals, proposal);
        dao.next_proposal_id = dao.next_proposal_id + 1;
    }

    public entry fun vote_on_proposal(
        voter: &signer,
        proposal_id: u64,
        vote_for: bool,
        voting_power: u64
    ) acquires DAO, GovernanceToken {
        let voter_addr = signer::address_of(voter);
        pausable::when_not_paused(voter_addr);
        
        // Verify voting power (simplified)
        let _token = borrow_global<GovernanceToken>(@dao);
        
        let dao = borrow_global_mut<DAO>(@dao);
        let proposal = vector::borrow_mut(&mut dao.proposals, proposal_id - 1);
        
        assert!(proposal.status == 0, 2); // Must be active
        assert!(aptos_framework::timestamp::now_seconds() <= proposal.voting_end, 3);
        
        if (vote_for) {
            proposal.votes_for = proposal.votes_for + voting_power;
        } else {
            proposal.votes_against = proposal.votes_against + voting_power;
        };
    }

    public entry fun execute_proposal(
        executor: &signer,
        proposal_id: u64
    ) acquires DAO {
        let executor_addr = signer::address_of(executor);
        assert!(access_control::has_role(executor_addr, EXECUTOR_ROLE), 1);
        
        let dao = borrow_global_mut<DAO>(@dao);
        let proposal = vector::borrow_mut(&mut dao.proposals, proposal_id - 1);
        
        assert!(proposal.status == 1, 2); // Must be passed
        assert!(proposal.votes_for > dao.quorum_threshold, 3);
        
        proposal.status = 3; // Executed
        
        // Execute proposal logic here
    }
}
```

---

## Advanced Integration Patterns

### Multi-Module Security Layer

```move
module enterprise::secure_platform {
    use std::signer;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::pausable;
    use move_security::block_limiter;
    use move_security::capability_store;

    const ADMIN_ROLE: vector<u8> = b"ADMIN";
    const OPERATOR_ROLE: vector<u8> = b"OPERATOR";
    const USER_ROLE: vector<u8> = b"USER";

    struct PlatformCapability has store {}
    
    struct SecurityPolicy has key {
        max_operations_per_block: u64,
        max_operations_per_hour: u64,
        emergency_contacts: vector<address>,
        maintenance_mode: bool,
    }

    public entry fun initialize_platform(owner: &signer) {
        // Initialize all security modules
        ownable::initialize_ownership(owner);
        access_control::initialize_access_control(owner);
        pausable::initialize_pausable(owner);
        capability_store::initialize_store<PlatformCapability>(owner);
        
        // Set up rate limiting
        block_limiter::initialize_block_limiter(owner, 50, 5000, 50000);
        
        // Create role hierarchy
        let owner_addr = signer::address_of(owner);
        access_control::setup_role(owner, ADMIN_ROLE, access_control::default_admin_role());
        access_control::setup_role(owner, OPERATOR_ROLE, ADMIN_ROLE);
        access_control::setup_role(owner, USER_ROLE, OPERATOR_ROLE);
        
        // Grant admin role to owner
        access_control::grant_role(owner, ADMIN_ROLE, owner_addr);
        
        // Store platform capability
        let platform_cap = PlatformCapability {};
        capability_store::store_capability(owner, platform_cap);
        
        // Initialize security policy
        let policy = SecurityPolicy {
            max_operations_per_block: 50,
            max_operations_per_hour: 5000,
            emergency_contacts: vector::singleton(owner_addr),
            maintenance_mode: false,
        };
        move_to(owner, policy);
    }

    public entry fun secure_operation(
        user: &signer,
        operation_type: u8
    ) acquires SecurityPolicy {
        let user_addr = signer::address_of(user);
        
        // Multi-layer security checks
        
        // 1. Check if platform is paused
        pausable::when_not_paused(user_addr);
        
        // 2. Check rate limits
        block_limiter::check_and_update_limits(user_addr);
        
        // 3. Check user permissions
        assert!(access_control::has_role(user_addr, USER_ROLE), 1);
        
        // 4. Check maintenance mode
        let policy = borrow_global<SecurityPolicy>(@enterprise);
        assert!(!policy.maintenance_mode, 2);
        
        // Execute operation based on type
        if (operation_type == 1) {
            // Regular operation
        } else if (operation_type == 2) {
            // Premium operation - requires operator role
            assert!(access_control::has_role(user_addr, OPERATOR_ROLE), 3);
        } else {
            abort 4 // Unknown operation type
        };
    }

    public entry fun admin_emergency_action(
        admin: &signer,
        action_type: u8
    ) acquires SecurityPolicy {
        let admin_addr = signer::address_of(admin);
        assert!(access_control::has_role(admin_addr, ADMIN_ROLE), 1);
        
        // Extract platform capability for admin actions
        let _platform_cap = capability_store::extract_capability<PlatformCapability>(admin);
        
        if (action_type == 1) {
            // Emergency pause
            pausable::pause(admin);
        } else if (action_type == 2) {
            // Enable maintenance mode
            let policy = borrow_global_mut<SecurityPolicy>(@enterprise);
            policy.maintenance_mode = true;
        } else if (action_type == 3) {
            // Update rate limits
            block_limiter::update_limits(admin, 10, 1000, 10000);
        };
        
        // Store capability back
        capability_store::store_capability(admin, _platform_cap);
    }

    public entry fun delegate_admin_capability(
        current_admin: &signer,
        new_admin: address
    ) {
        let current_admin_addr = signer::address_of(current_admin);
        ownable::require_owner(current_admin_addr);
        
        // Delegate platform capability
        let platform_cap = capability_store::extract_capability<PlatformCapability>(current_admin);
        capability_store::delegate_store(current_admin, new_admin, platform_cap);
        
        // Grant admin role to new admin
        access_control::grant_role(current_admin, ADMIN_ROLE, new_admin);
    }
}
```

### Cross-Module Communication Pattern

```move
module integration::module_bridge {
    use std::signer;
    use move_security::ownable;
    use move_security::access_control;
    use move_security::capability_store;

    // Bridge capabilities for cross-module operations
    struct BridgeCapability<phantom T> has store {}
    
    struct ModuleBridge has key {
        registered_modules: vector<address>,
        active_bridges: u64,
    }

    public fun initialize_bridge(admin: &signer) {
        ownable::initialize_ownership(admin);
        access_control::initialize_access_control(admin);
        capability_store::initialize_store<BridgeCapability<u8>>(admin);
        
        let bridge = ModuleBridge {
            registered_modules: vector::empty(),
            active_bridges: 0,
        };
        move_to(admin, bridge);
    }

    public fun register_module<T>(
        admin: &signer,
        module_addr: address
    ) acquires ModuleBridge {
        let admin_addr = signer::address_of(admin);
        ownable::require_owner(admin_addr);
        
        let bridge = borrow_global_mut<ModuleBridge>(@integration);
        vector::push_back(&mut bridge.registered_modules, module_addr);
        
        // Create bridge capability for the module
        let bridge_cap = BridgeCapability<T> {};
        capability_store::store_capability(admin, bridge_cap);
        
        bridge.active_bridges = bridge.active_bridges + 1;
    }

    public fun execute_cross_module_operation<T>(
        caller: &signer,
        target_module: address,
        operation_data: vector<u8>
    ): vector<u8> acquires ModuleBridge {
        let caller_addr = signer::address_of(caller);
        
        let bridge = borrow_global<ModuleBridge>(@integration);
        assert!(vector::contains(&bridge.registered_modules, &target_module), 1);
        
        // Extract bridge capability
        let _bridge_cap = capability_store::extract_capability<BridgeCapability<T>>(caller);
        
        // Execute cross-module operation
        let result = execute_operation_internal(target_module, operation_data);
        
        // Store capability back
        capability_store::store_capability(caller, _bridge_cap);
        
        result
    }

    fun execute_operation_internal(
        _target_module: address,
        operation_data: vector<u8>
    ): vector<u8> {
        // Internal cross-module communication logic
        operation_data // Simplified return
    }
}
```

This comprehensive usage guide demonstrates how to integrate and use the OpenZeppelin Move security modules across various blockchain application scenarios, from simple ownership control to complex multi-module enterprise platforms. 