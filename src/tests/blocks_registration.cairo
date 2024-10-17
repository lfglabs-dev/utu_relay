use crate::{
    utils::hex::hex_to_hash_rev,
    bitcoin::block::{BlockHeader, BlockHashTrait, HumanReadableBlockHeader}
};

#[test]
fn test_single_block_registration() {
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

    assert(computed_hash == expected_hash, 'Block hash mismatch');
}
