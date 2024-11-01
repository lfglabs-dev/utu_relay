use crate::{bitcoin::block::BlockHeader, utils::digest::DigestStore};
use starknet::get_block_timestamp;
use utils::hash::Digest;


#[derive(Drop, Serde, Debug, Default, PartialEq, starknet::Store)]
pub struct BlockStatus {
    // to do: instead of storing the prev_block_digest, we could store its potential address in
    // memory
    pub registration_timestamp: u64,
    pub prev_block_digest: Digest,
    pub pow: u128,
}

#[derive(Drop, Serde, Debug, PartialEq)]
pub struct HeightProof {
    pub header: BlockHeader,
    pub coinbase_raw_tx: ByteArray,
    pub merkle_branch: Span<Digest>
}

// todo: move out of interfaces
#[generate_trait]
pub impl BlockStatusImpl of BlockStatusTrait {
    fn is_empty(self: @BlockStatus) -> bool {
        *self.registration_timestamp == 0
    }

    fn new(prev_block_digest: Digest, pow: u128) -> BlockStatus {
        BlockStatus { prev_block_digest, registration_timestamp: get_block_timestamp(), pow, }
    }
}

#[starknet::interface]
pub trait IUtuRelay<TContractState> {
    /// Registers new blocks with the relay.
    ///
    /// This function allows anyone to register blocks (they don't have to be contiguous or in
    /// order). It verifies that each registered block passes its threshold.
    ///
    /// Note: Registered blocks are not automatically included in the canonical chain.
    fn register_blocks(ref self: TContractState, blocks: Span<BlockHeader>);

    /// Sets the canonical chain for a given interval.
    ///
    /// This function allows setting the "official chain" (the strongest one) over the provided
    /// interval. It starts from the end block hash and verifies that this hash and all its
    /// parents are registered. The interval is specified as [ begin, end [.
    ///
    /// The `height_proof` parameter is an optional tuple containing:
    /// 1. The raw coinbase transaction of the first block in the interval.
    /// 2. A Span of Digest values representing the brother hashes needed to verify the merkle root.
    ///
    /// This height_proof is required to verify the block height when chain[begin-1] is not set.
    /// If chain[begin-1] is already set, height_proof can be omitted.
    fn update_canonical_chain(
        ref self: TContractState,
        begin_height: u64,
        end_height: u64,
        end_block_hash: Digest,
        height_proof: Option<HeightProof>
    );

    /// Returns the status of a block given its hash.
    ///
    /// This function retrieves information about any registered block, regardless of whether
    /// it is part of the canonical chain or not. The returned status includes:
    /// - registration_timestamp: when the block was registered
    /// - prev_block_digest: hash of the previous block
    /// - pow: proof of work value
    fn get_status(self: @TContractState, block_hash: Digest) -> BlockStatus;

    /// Returns the hash of the block at the specified height in the canonical chain.
    ///
    /// This function retrieves the block hash for a given height in the canonical chain.
    /// If no block is set at this height, it returns an empty Digest (Zero::zero()).
    fn get_block(self: @TContractState, height: u64) -> Digest;

    /// Asserts that a block meets the specified safety requirements.
    /// Reverts if the block does not meet the safety requirements.
    fn assert_safe(
        self: @TContractState, block_height: u64, block_hash: Digest, min_cpow: u128, min_age: u64,
    );
}
