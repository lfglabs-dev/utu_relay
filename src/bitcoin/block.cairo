use crate::utils::{
    pow2::pow2, numeric::u32_byte_reverse, hash::Digest, double_sha256::double_sha256_u32_array
};

/// Bitcoin block header structure based on:
/// https://developer.bitcoin.org/reference/block_chain.html#block-headers
///
/// The block header consists of the following fields:
/// - version: Block version number
/// - prev_block_hash: 256-bit hash of the previous block header
/// - merkle_root_hash: 256-bit hash based on all transactions in the block
/// - time: Current block timestamp as seconds since 1970-01-01T00:00 UTC
/// - bits: Current target in compact format
/// - nonce: 32-bit number (starts at 0)
///
/// Note: All fields in this struct are in Little Endian format.

#[derive(Drop, Copy, Debug, PartialEq, Default, Serde)]
pub struct BlockHeader {
    pub version: u32,
    pub prev_block_hash: Digest,
    pub merkle_root_hash: Digest,
    pub time: u32,
    pub bits: u32,
    pub nonce: u32,
}

/// HumanReadableBlockHeader is provided for testing purposes.
/// In Cairo, the default encoding is big-endian, so this struct allows
/// creation of a BlockHeader from human-readable values.
/// Note: The Digest fields are already in little-endian format.

#[derive(Drop, Copy, Debug, PartialEq, Default, Serde)]
pub struct HumanReadableBlockHeader {
    pub version: u32,
    pub prev_block_hash: Digest,
    pub merkle_root_hash: Digest,
    pub time: u32,
    pub bits: u32,
    pub nonce: u32,
}

impl IntoBlockHeader of Into<HumanReadableBlockHeader, BlockHeader> {
    fn into(self: HumanReadableBlockHeader) -> BlockHeader {
        BlockHeader {
            version: u32_byte_reverse(self.version),
            prev_block_hash: self.prev_block_hash,
            merkle_root_hash: self.merkle_root_hash,
            time: u32_byte_reverse(self.time),
            bits: u32_byte_reverse(self.bits),
            nonce: u32_byte_reverse(self.nonce),
        }
    }
}

#[generate_trait]
pub impl BlockHashImpl of BlockHashTrait {
    /// Compute the block hash
    fn hash(self: @BlockHeader) -> Digest {
        let mut header_data_u32: Array<u32> = array![];

        header_data_u32.append(*self.version);
        header_data_u32.append_span(self.prev_block_hash.value.span());
        header_data_u32.append_span(self.merkle_root_hash.value.span());

        header_data_u32.append(*self.time);
        header_data_u32.append(*self.bits);
        header_data_u32.append(*self.nonce);

        double_sha256_u32_array(header_data_u32)
    }
}

#[generate_trait]
pub impl PowVerificationImpl of PowVerificationTrait {
    /// Computes the Proof of Work (PoW) for the block.
    /// Returns the expected number of hashes that would need to be generated
    /// to reach the block's difficulty target.
    fn compute_pow(self: @BlockHeader) -> u128 {
        let (exponent, mantissa) = core::traits::DivRem::div_rem(*self.bits, 0x1000000);
        (pow2(256 - 8 * (exponent - 3)) / mantissa.into())
    }
}


#[cfg(test)]
mod tests {
    use super::PowVerificationTrait;
    use crate::utils::hex::{hex_to_hash_rev};
    use super::{BlockHeader, HumanReadableBlockHeader, BlockHashTrait};


    #[test]
    fn test_block_hash() {
        // Create a HumanReadablBlockHeader from block 170
        let human_readable_header = HumanReadableBlockHeader {
            version: 1_u32,
            prev_block_hash: hex_to_hash_rev(
                "000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55"
            ),
            merkle_root_hash: hex_to_hash_rev(
                "7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff"
            ),
            time: 1231731025_u32,
            bits: 0x1d00ffff_u32,
            nonce: 1889418792,
        };

        // Convert to full little endian BlockHeader
        let header: BlockHeader = human_readable_header.into();

        // Compute the hash
        let computed_hash = header.hash();

        // Expected hash (reversed because we're working with big-endian)
        let expected_hash = hex_to_hash_rev(
            "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"
        );

        assert_eq!(computed_hash, expected_hash, "Computed hash does not match expected hash");
    }

    #[test]
    fn test_pow() {
        // Block 170
        let human_readable_header = HumanReadableBlockHeader {
            version: 1_u32,
            prev_block_hash: hex_to_hash_rev(
                "000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55"
            ),
            merkle_root_hash: hex_to_hash_rev(
                "7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff"
            ),
            time: 1231731025_u32,
            bits: 0x1d00ffff_u32,
            nonce: 1889418792,
        };

        let header: BlockHeader = human_readable_header.into();
        let pow = header.compute_pow();
        // This is an estimation of the amount of hashes to compute a valid block hash
        assert_eq!(pow, 4_295_032_833);
    }
}
