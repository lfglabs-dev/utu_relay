use crate::{utils::hash::Digest, bitcoin::block::BlockHeader};
use starknet::get_block_timestamp;

#[derive(Drop, Serde, Debug, Default, PartialEq, starknet::Store)]
pub struct BlockStatus {
    // to do: instead of storing the prev_block_digest, we could store its potential address in
    // memory
    pub registration_timestamp: u64,
    pub prev_block_digest: Digest,
    pub challenged_cpow: u128,
    pub pow: u128,
}

// todo: move out of interfaces
#[generate_trait]
pub impl BlockStatusImpl of BlockStatusTrait {
    fn is_empty(self: @BlockStatus) -> bool {
        *self.registration_timestamp == 0
    }

    fn new(prev_block_digest: Digest, pow: u128) -> BlockStatus {
        BlockStatus {
            prev_block_digest,
            registration_timestamp: get_block_timestamp(),
            challenged_cpow: 0,
            pow,
        }
    }
}

#[starknet::interface]
pub trait IUtuRelay<TContractState> {
    /// Registers new blocks with the relay.
    ///
    /// This function allows anyone to register blocks (they don't have to be contiguous or in
    /// order). It verifies that each registered block passes its threshold.
    ///
    /// Note: Registered blocks are not automatically included in the main chain.
    fn register_blocks(ref self: TContractState, blocks: Span<BlockHeader>);

    /// Sets the main chain for a given interval.
    ///
    /// This function allows setting the "official chain" (the strongest one) over the provided
    /// interval. It starts from the end block hash and verifies that this hash and all its
    /// parents are registered. The interval is specified as [ begin, end [.
    fn set_main_chain(
        ref self: TContractState, begin_height: u64, end_height: u64, end_block_hash: Digest
    );

    fn challenge_block(
        ref self: TContractState, block_height: u64, blocks: Array<BlockHeader>
    ) -> bool;

    fn get_status(self: @TContractState, block_hash: Digest) -> BlockStatus;
}
