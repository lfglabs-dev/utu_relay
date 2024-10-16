use crate::{utils::hash::Digest, bitcoin::block::BlockHeader};
use starknet::get_block_timestamp;

#[derive(Drop, Serde, Default, starknet::Store)]
pub struct BlockStatus {
    pub digest: Digest,
    pub challenged_cpow: u128,
    pub registration_timestamp: u64,
    pub pow: u128,
}

// todo: move out of interfaces
#[generate_trait]
pub impl BlockStatusImpl of BlockStatusTrait {
    fn is_empty(self: @BlockStatus) -> bool {
        *self.registration_timestamp == 0
    }

    fn new(digest: Digest, pow: u128) -> BlockStatus {
        BlockStatus {
            digest, challenged_cpow: 0, registration_timestamp: get_block_timestamp(), pow,
        }
    }
}

#[starknet::interface]
pub trait IUtuRelay<TContractState> {
    fn register_blocks(
        ref self: TContractState,
        starting_height: u64,
        height_proof: Option<felt252>,
        blocks: Span<BlockHeader>
    ) -> bool;

    fn challenge_block(
        ref self: TContractState, block_height: u64, blocks: Array<BlockHeader>
    ) -> bool;

    fn get_status(self: @TContractState, block_height: u64) -> Option<BlockStatus>;
}
