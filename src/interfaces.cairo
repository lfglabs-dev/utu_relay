use crate::{utils::hash::Digest, bitcoin::block::BlockHeader};

#[derive(Drop, Serde)]
pub struct BlockStatus {
    digest: Digest,
    challenged_cpow: u128,
    registration_timestamp: u64,
    cumulative_pow: u128,
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
