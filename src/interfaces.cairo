#[derive(Drop, Serde)]
pub struct BlockStatus {
    digest: Digest,
    challenged_cpow: u128,
    registration_timestamp: u64,
    cumulative_pow: u128,
}

/// 256-bit hash digest.
/// Represented as an array of 4-byte words.
#[derive(Copy, Drop, Debug, Default, Serde)]
pub struct Digest {
    pub value: [u32; 8]
}

impl DigestPartialEq of PartialEq<Digest> {
    fn eq(lhs: @Digest, rhs: @Digest) -> bool {
        lhs.value == rhs.value
    }
}

#[derive(Drop, Copy, Debug, PartialEq, Default, Serde)]
pub struct BlockHeader {
    /// Hash of the block.
    pub hash: Digest,
    /// The version of the block.
    pub version: u32,
    /// The timestamp of the block.
    pub time: u32,
    /// The difficulty target for mining the block.
    /// Not strictly necessary since it can be computed from target,
    /// but it is cheaper to validate than compute.
    pub bits: u32,
    /// The nonce used in mining the block.
    pub nonce: u32,
}


#[starknet::interface]
pub trait IUtuRelay<TContractState> {
    fn register_blocks(
        ref self: TContractState,
        starting_height: u64,
        height_proof: Option<felt252>,
        blocks: Array<BlockHeader>
    ) -> bool;

    fn challenge_block(
        ref self: TContractState, block_height: u64, blocks: Array<BlockHeader>
    ) -> bool;

    fn get_status(self: @TContractState, block_height: u64) -> Option<BlockStatus>;
}
