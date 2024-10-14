use crate::utils::hash::Digest;

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
