#[starknet::contract]
pub mod UtuRelay {
    use starknet::storage::StorageMapWriteAccess;
    use crate::{
        utils::hash::Digest,
        bitcoin::block::{
            BlockHeader, BlockHashTrait, PowVerificationTrait, compute_pow_from_target
        },
        interfaces::{IUtuRelay, BlockStatus, BlockStatusTrait}
    };
    use starknet::storage::{StorageMapReadAccess, Map};

    #[storage]
    struct Storage {
        blocks: Map<u64, BlockStatus>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl UtuRelayImpl of IUtuRelay<ContractState> {
        fn register_blocks(
            ref self: ContractState,
            starting_height: u64,
            height_proof: Option<felt252>,
            mut blocks: Span<BlockHeader>
        ) -> bool {
            // Implementation for register_blockss
            // For now, we'll just return false
            let prev_block = self.blocks.read(starting_height - 1);
            self.register_blocks_helper(starting_height, blocks, prev_block.digest);
            false
        }

        fn challenge_block(
            ref self: ContractState, block_height: u64, blocks: Array<BlockHeader>
        ) -> bool {
            // Implementation for challenge_block
            // For now, we'll just return false
            false
        }

        fn get_status(self: @ContractState, block_height: u64) -> Option<BlockStatus> {
            // Implementation for get_status
            // For now, we'll just return None
            Option::None
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn register_blocks_helper(
            ref self: ContractState,
            height: u64,
            mut blocks: Span<BlockHeader>,
            mut prev_hash: Digest,
        ) -> u128 {
            match blocks.pop_front() {
                Option::None => { 0 },
                Option::Some(block) => {
                    let block_hash = block.hash();
                    let next_cpow = self.register_blocks_helper(height + 1, blocks, block_hash);
                    let target_threshold = block.compute_target_threshold();
                    // verifies pow spent
                    if block_hash.into() < target_threshold {
                        panic!("Block hash is higher than its target threshold.");
                    };

                    let pow = compute_pow_from_target(target_threshold);
                    let existing_block = self.blocks.read(height);
                    let cpow = next_cpow + pow;
                    if !existing_block.is_empty() && existing_block.digest != block_hash {
                        // todo: computing existing_block cpow and compare to cpow or panic
                        // todo: optimize to avoid recomputing alt cpow
                        panic!("You can't overwrite a block with a higher cumulated pow.");
                    };
                    self.blocks.write(height, BlockStatusTrait::new(block_hash, pow));
                    // todo: check hash connection before AND after?
                    cpow
                }
            }
        }
    }
}
