use crate::utils::{
    pow2::{pow2_u128, pow2_u256}, numeric::u32_byte_reverse, hash::Digest,
    double_sha256::double_sha256_u32_array
};
use core::traits::DivRem;

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
// todo: BlockHeader with HumanReadable constructor and default one?
#[derive(Drop, Copy, Debug, PartialEq, Default, Serde)]
pub struct HumanReadableBlockHeader {
    pub version: u32,
    pub prev_block_hash: Digest,
    pub merkle_root_hash: Digest,
    pub time: u32,
    pub bits: u32,
    pub nonce: u32,
}

// todo: Precompiled Block Header?
impl IntoBlockHeader of Into<HumanReadableBlockHeader, BlockHeader> {
    fn into(self: HumanReadableBlockHeader) -> BlockHeader {
        BlockHeader {
            version: u32_byte_reverse(self.version),
            prev_block_hash: self.prev_block_hash,
            merkle_root_hash: self.merkle_root_hash,
            time: u32_byte_reverse(self.time),
            // we want to keep bits in little endian to allow for pow computation
            // todo: split mantissa and precompute reversed?
            bits: self.bits,
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
        // bits is not stored in little endian
        header_data_u32.append(u32_byte_reverse(*self.bits));
        header_data_u32.append(*self.nonce);

        double_sha256_u32_array(header_data_u32)
    }
}

/// Maximum difficulty target allowed
const MAX_TARGET: u256 = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;


#[generate_trait]
pub impl PowVerificationImpl of PowVerificationTrait {
    /// Computes the Proof of Work (PoW) for the block.
    /// Returns the expected number of hashes that would need to be generated
    /// to reach the block's difficulty target.
    fn compute_pow(self: @BlockHeader) -> u128 {
        let (exponent, mantissa) = DivRem::div_rem(*self.bits, 0x1000000);
        (pow2_u128(256 - 8 * (exponent - 3)) / mantissa.into())
    }

    /// Computes the target threshold for the block.
    /// todo: optimize for errors and maths
    fn compute_target_threshold(self: @BlockHeader) -> u256 {
        let (exponent, mantissa) = DivRem::div_rem(*self.bits, 0x1000000);

        if exponent == 0 {
            // Special case: exponent 0 means we use the mantissa as-is
            return mantissa.into();
        }

        // Check if mantissa is valid (most significant byte has to be < 0x80)
        // https://bitcoin.stackexchange.com/questions/113535/why-1d00ffff-and-not-1cffffff-as-target-in-genesis-block
        if mantissa > 0x7FFFFF {
            panic!("Target cannot have most significant bit set");
        };

        // Calculate the full target value
        if exponent <= 3 {
            let shift = 8 * (3 - exponent);
            // MAX_TARGET > 2^128 so we can return early
            (mantissa.into() / pow2_u128(shift)).into()
        } else if exponent <= 32 {
            let shift = 8 * (exponent - 3);
            let target = (mantissa.into() * pow2_u256(shift));
            // Ensure the target doesn't exceed the maximum allowed value
            if target > MAX_TARGET {
                panic!("Target exceeds maximum value");
            }
            target
        } else {
            panic!("Target size cannot exceed 32 bytes")
        }
    }
}

pub fn compute_pow_from_target(target: u256) -> u128 {
    // For exactly all positive integers x that are not factors of 2^256,
    // (2^256-1)/x = (2^256)/x
    // Otherwise, we just misestimate by 1
    // todo: optimize
    let max_value: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    (max_value / target).try_into().unwrap()
}

#[cfg(test)]
mod tests {
    use super::{
        BlockHeader, HumanReadableBlockHeader, BlockHashTrait, PowVerificationTrait,
        compute_pow_from_target
    };
    use crate::utils::hex::hex_to_hash_rev;

    // compute block hash tests

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


    // compute_pow tests

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


    #[test]
    fn test_pow_from_target() {
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
        let target = header.compute_target_threshold();
        let pow = compute_pow_from_target(target);
        // This is an estimation of the amount of hashes to compute a valid block hash
        assert_eq!(pow, 4_295_032_833);
    }

    // compute_target_threshold tests

    #[test]
    fn test_target_threshold_01003456() {
        let header = BlockHeader { bits: 0x01003456, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(result, 0x00_u256, "Incorrect target for 0x01003456");
    }

    #[test]
    fn test_target_threshold_01123456() {
        let header = BlockHeader { bits: 0x01123456, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(result, 0x12_u256, "Incorrect target for 0x01123456");
    }

    #[test]
    fn test_target_threshold_02008000() {
        let header = BlockHeader { bits: 0x02008000, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(result, 0x80_u256, "Incorrect target for 0x02008000");
    }

    #[test]
    fn test_target_threshold_181bc330() {
        let header = BlockHeader { bits: 0x181bc330, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(
            result,
            0x1bc330000000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x181bc330"
        );
    }

    #[test]
    fn test_target_threshold_05009234() {
        let header = BlockHeader { bits: 0x05009234, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(result, 0x92340000_u256, "Incorrect target for 0x05009234");
    }

    #[test]
    fn test_target_threshold_04123456() {
        let header = BlockHeader { bits: 0x04123456, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(result, 0x12345600_u256, "Incorrect target for 0x04123456");
    }

    #[test]
    fn test_target_threshold_1d00ffff() {
        let header = BlockHeader { bits: 0x1d00ffff, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(
            result,
            0x00000000ffff0000000000000000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x1d00ffff"
        );
    }

    #[test]
    fn test_target_threshold_1c0d3142() {
        let header = BlockHeader { bits: 0x1c0d3142, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(
            result,
            0x000000000d314200000000000000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x1c0d3142"
        );
    }

    #[test]
    fn test_target_threshold_1707a429() {
        let header = BlockHeader { bits: 0x1707a429, ..Default::default() };
        let result = header.compute_target_threshold();
        assert_eq!(
            result,
            0x00000000000000000007a4290000000000000000000000000000000000000000_u256,
            "Incorrect target for 0x1707a429"
        );
    }

    #[test]
    #[should_panic(expected: "Target cannot have most significant bit set")]
    fn test_target_threshold_msb_set() {
        let header = BlockHeader { bits: 0x03800000, ..Default::default() };
        header.compute_target_threshold();
    }

    #[test]
    #[should_panic(expected: "Target size cannot exceed 32 bytes")]
    fn test_target_threshold_exponent_too_large() {
        let header = BlockHeader { bits: 0x2100aa00, ..Default::default() };
        header.compute_target_threshold();
    }

    #[test]
    #[should_panic(expected: "Target exceeds maximum value")]
    fn test_target_threshold_exceeds_max() {
        let header = BlockHeader { bits: 0x20010000, ..Default::default() };
        header.compute_target_threshold();
    }
}
