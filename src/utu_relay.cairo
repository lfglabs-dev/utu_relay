#[starknet::contract]
pub mod UtuRelay {
    use starknet::storage::{StorageMapWriteAccess};
    use crate::{
        bitcoin::{
            block::{BlockHeader, BlockHashTrait, PowVerificationTrait, compute_pow_from_target},
            block_height::get_block_height
        },
        utils::digest::DigestStore,
        interfaces::{IUtuRelay, BlockStatus, HeightProof, BlockStatusTrait}
    };
    use starknet::storage::{
        StorageMapReadAccess, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
        Map
    };
    use utils::hash::Digest;
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


        fn update_canonical_chain(
            ref self: ContractState,
            begin_height: u64,
            mut end_height: u64,
            end_block_hash: Digest,
            height_proof: Option<HeightProof>
        ) {
            let mut requires_height_proof = true;
            // This helper will write the ancestry of end_block_hash over [begin_height, end_height]
            // with chain[end_height] holding end_block_hash. If it overwrote some blocks, it
            // returns the cumulated pow of the overwritten blocks (current) and the fork (new).
            let (mut current_cpow, new_cpow) = self
                .update_canonical_chain_helper(
                    ref requires_height_proof, end_block_hash, end_height, begin_height - 1
                );

            if requires_height_proof {
                match height_proof {
                    Option::None => {
                        panic!(
                            "You must provide a height proof if you don't continue the canonical chain."
                        )
                    },
                    Option::Some(height_proof) => {
                        if self.chain.read(begin_height) != height_proof.header.hash() {
                            panic!(
                                "Your provided proof doesn't correspond to the begin block height."
                            );
                        };
                        let extracted_height = get_block_height(@height_proof);
                        if extracted_height != begin_height {
                            panic!("Your provided proof doesn't prove the correct height.");
                        };
                    }
                }
            };

            let mut next_block_i = end_height + 1;
            let mut next_chain_entry = self.chain.entry(next_block_i);
            let mut next_block_digest = next_chain_entry.read();
            let mut next_block = self.blocks.read(next_block_digest);
            // if there is a conflict with next blocks
            if next_block.prev_block_digest != end_block_hash {
                // we want to account for the current_cpow by blocks > to end_height
                loop {
                    if next_block_digest == Zero::zero() {
                        break;
                    }

                    // we remove the conflicting blocks from the canonical chain
                    // but this will be cancelled by the panic if we are wrong
                    next_chain_entry.write(Zero::zero());

                    // we increase the current_cpow
                    current_cpow += next_block.pow;
                    next_block_i += 1;
                    next_chain_entry = self.chain.entry(next_block_i);
                    next_block_digest = next_chain_entry.read();
                    next_block = self.blocks.read(next_block_digest)
                };
            }

            // and automatically revert everything if the fork cpow is weaker
            if current_cpow >= new_cpow {
                panic!("Canonical chain has a stronger cumulated pow than your proposed fork.");
            }
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
        fn update_canonical_chain_helper(
            ref self: ContractState,
            ref requires_height_proof: bool,
            new_block_digest: Digest,
            block_index: u64,
            stop_index: u64,
        ) -> (u128, u128) {
            // fetch the block stored in the chain
            let block_digest_entry = self.chain.entry(block_index);
            let current_block_digest = block_digest_entry.read();

            // Ensure consistency with previous blocks
            // This check prevents setting inconsistent values without comparing PoW
            // If there's a conflict with a more recent block, provide replacement blocks
            // The function will panic if inconsistency is detected to save gas
            // For honest users, simply provide the correct replacement blocks
            if block_index == stop_index {
                // new_block_digest is previous_block_digest of his son we just processed
                if current_block_digest != Zero::zero() {
                    if current_block_digest != new_block_digest {
                        panic!(
                            "Canonical chain block preceding your proposed fork is inconsistent. Please provide a stronger replacement."
                        );
                    } else {
                        // if there is a valid connecting block, we don't need a height_proof
                        requires_height_proof = false;
                    };
                }

                return (0, 0);
            }

            // retrieve the blocks
            let current_block = self.blocks.read(current_block_digest);
            let new_block = self.blocks.read(new_block_digest);

            // replace the block stored in the chain
            block_digest_entry.write(new_block_digest);

            let (cpow, new_cpow) = self
                .update_canonical_chain_helper(
                    ref requires_height_proof,
                    new_block.prev_block_digest,
                    block_index - 1,
                    stop_index
                );

            // if there was no conflict before
            if current_block_digest == new_block_digest {
                // this block was already present, no need for a height proof
                requires_height_proof = false;
                return (0, 0);
                // if there was a conflict (may be), we measure cpow & new_cpow
            } else {
                return (cpow + current_block.pow, new_cpow + new_block.pow);
            }
        }
    }
}
