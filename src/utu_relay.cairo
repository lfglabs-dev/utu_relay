#[starknet::contract]
pub mod UtuRelay {
    use starknet::storage::{StorageMapWriteAccess};
    use crate::{
        utils::hash::Digest,
        bitcoin::block::{
            BlockHeader, BlockHashTrait, PowVerificationTrait, compute_pow_from_target
        },
        interfaces::{IUtuRelay, BlockStatus, BlockStatusTrait}
    };
    use starknet::storage::{
        StorageMapReadAccess, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
        Map
    };
    use core::num::traits::zero::Zero;


    #[storage]
    struct Storage {
        // This is an acyclic graph which contains all blocks registered, including those from forks
        blocks: Map<Digest, BlockStatus>,
        // This is a mapping of each chain height to a block from the strongest chain registered
        chain: Map<u64, Digest>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl UtuRelayImpl of IUtuRelay<ContractState> {
        fn register_blocks(ref self: ContractState, mut blocks: Span<BlockHeader>) {
            loop {
                match blocks.pop_front() {
                    Option::None => { break; },
                    Option::Some(block) => {
                        let block_hash = block.hash();
                        let target_threshold = block.compute_target_threshold();
                        // verifies pow spent
                        if block_hash.into() > target_threshold {
                            panic!("Block hash is higher than its target threshold.");
                        };
                        // estimate pow value
                        let pow = compute_pow_from_target(target_threshold);
                        self
                            .blocks
                            .write(block_hash, BlockStatusTrait::new(*block.prev_block_hash, pow));
                    }
                };
            };
        }


        fn set_main_chain(
            ref self: ContractState, begin_height: u64, mut end_height: u64, end_block_hash: Digest
        ) {
            // This helper will write the ancestry of end_block_hash over [begin_height, end_height]
            // with chain[end_height] holding end_block_hash. If it overwrote some blocks, it
            // returns the cumulated pow of the overwritten blocks (current) and the fork (new).
            let (mut current_cpow, new_cpow) = self
                .set_main_chain_helper(end_block_hash, end_height, begin_height - 1);

            // if there was no conflict
            if current_cpow == 0 {
                return;
            }

            // otherwise, we want to account for the current_cpow by blocks > to end_height
            let mut next_block_i = end_height + 1;
            loop {
                let next_block_digest = self.chain.read(next_block_i);
                if next_block_digest == Zero::zero() {
                    break;
                }

                current_cpow += self.blocks.read(next_block_digest).pow;
                next_block_i += 1;
            };

            // and automatically revert everything if the fork cpow is weaker
            if current_cpow >= new_cpow {
                panic!("Main chain has a stronger cumulated pow than your proposed fork.");
            }
        }


        fn challenge_block(
            ref self: ContractState, block_height: u64, blocks: Array<BlockHeader>
        ) -> bool {
            // Implementation for challenge_block
            // For now, we'll just return false
            false
        }

        fn get_status(self: @ContractState, block_hash: Digest) -> BlockStatus {
            self.blocks.read(block_hash)
        }

        fn get_block(self: @ContractState, height: u64) -> Digest {
            self.chain.read(height)
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn set_main_chain_helper(
            ref self: ContractState, new_block_digest: Digest, block_index: u64, stop_index: u64,
        ) -> (u128, u128) {
            if block_index == stop_index {
                return (0, 0);
            }

            // update the block stored in the chain
            let block_digest_entry = self.chain.entry(block_index);
            let current_block_digest = block_digest_entry.read();
            block_digest_entry.write(new_block_digest);

            // retrieve the blocks
            let current_block = self.blocks.read(current_block_digest);
            let new_block = self.blocks.read(new_block_digest);

            let (cpow, new_cpow) = self
                .set_main_chain_helper(new_block.prev_block_digest, block_index - 1, stop_index);

            // if there was no conflict before
            if current_block_digest == new_block_digest {
                return (0, 0);
                // if there was a conflict (may be), we measure cpow & new_cpow
            } else {
                return (cpow + current_block.pow, new_cpow + new_block.pow);
            }
        }
    }
}
