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
                        if block_hash.into() < target_threshold {
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
        ) { // override existing blocks starting at `end_height`
            let mut current_cpow: u128 = 0;
            let mut block_i = end_height;
            loop {
                let block_digest = self.chain.read(block_i);
                if block_digest == Zero::zero() {
                    break;
                }
                let block_entry = self.blocks.entry(block_digest);
                let block = block_entry.read();
                // we erase the block, this will get reverted if pow is not sufficient
                block_entry.write(Default::default());
                current_cpow += block.pow;
                block_i += 1;
            };

            // cancel if these existing blocks have a stronger cpow
            let new_block = self.blocks.read(end_block_hash);
            let mut new_cpow = new_block.pow;
            if new_cpow <= current_cpow {
                panic!("Main chain has a stronger cpow than your proposed fork last block pow.");
            };
            self.chain.write(end_height, end_block_hash);
            let mut block_hash = new_block.prev_block_digest;

            // write blocks
            loop {
                if begin_height == end_height {
                    break;
                };
                let block = self.blocks.read(block_hash);
                new_cpow += block.pow;
                end_height -= 1;

                // check if there is an existing block
                let block_hash_entry = self.chain.entry(end_height);
                // if there is no existing block, its pow will be 0
                if new_cpow <= self.blocks.read(block_hash_entry.read()).pow {
                    panic!("Main chain has a single block stronger than your proposed fork.");
                };
                block_hash_entry.write(block_hash);
                block_hash = block.prev_block_digest;
            };
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
}
