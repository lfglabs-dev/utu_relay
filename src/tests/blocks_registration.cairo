use super::super::interfaces::{IUtuRelayDispatcherTrait, BlockStatus};
use crate::{bitcoin::block::{BlockHeader, BlockHeaderTrait}, tests::utils::deploy_utu};
use utils::hex::hex_to_hash_rev;
use snforge_std::{start_cheat_block_timestamp};


#[test]
fn test_single_block_registration() {
    let utu = deploy_utu();
    start_cheat_block_timestamp(utu.contract_address, 1234567890);
    let block_170_hash = hex_to_hash_rev(
        "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"
    );

    let current_status = utu.get_status(block_170_hash);
    assert(current_status == Default::default(), 'unexpected initial status');

    let block_170: BlockHeader = BlockHeaderTrait::new(
        1_u32,
        hex_to_hash_rev("000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55"),
        hex_to_hash_rev("7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff"),
        1231731025_u32,
        0x1d00ffff_u32,
        1889418792,
    );

    // Load valid header from block 170
    let block_headers: Array<BlockHeader> = array![block_170];
    utu.register_blocks(block_headers.span());

    let found_status = utu.get_status(block_170_hash);
    assert(
        found_status == BlockStatus {
            registration_timestamp: 1234567890,
            prev_block_digest: hex_to_hash_rev(
                "000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55"
            ),
            pow: 4295032833,
        },
        'unexpected final status'
    );
}

#[test]
fn test_two_blocks_registration() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1234567890);

    // Block 170
    let block_170_hash = hex_to_hash_rev(
        "00000000d1145790a8694403d4063f323d499e655c83426834d4ce2f8dd4a2ee"
    );
    let block_170: BlockHeader = BlockHeaderTrait::new(
        1_u32,
        hex_to_hash_rev("000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55"),
        hex_to_hash_rev("7dac2c5666815c17a3b36427de37bb9d2e2c5ccec3f8633eb91a4205cb4c10ff"),
        1231731025_u32,
        0x1d00ffff_u32,
        1889418792,
    );

    // Block 171
    let block_171_hash = hex_to_hash_rev(
        "00000000c9ec538cab7f38ef9c67a95742f56ab07b0a37c5be6b02808dbfb4e0"
    );
    let block_171: BlockHeader = BlockHeaderTrait::new(
        1_u32,
        block_170_hash,
        hex_to_hash_rev("d5f2d21453a6f0e67b5c42959c9700853e4c4d46fa7519d1cc58e77369c893f2"),
        1231731401_u32,
        0x1d00ffff_u32,
        653436935,
    );

    // Register both blocks
    let block_headers: Array<BlockHeader> = array![block_170, block_171];
    utu.register_blocks(block_headers.span());

    // Check status of block 170
    let status_170 = utu.get_status(block_170_hash);
    assert(
        status_170 == BlockStatus {
            registration_timestamp: 1234567890,
            prev_block_digest: hex_to_hash_rev(
                "000000002a22cfee1f2c846adbd12b3e183d4f97683f85dad08a79780a84bd55"
            ),
            pow: 4295032833,
        },
        'unexpected status for block 170'
    );

    // Check status of block 171
    let status_171 = utu.get_status(block_171_hash);
    assert(
        status_171 == BlockStatus {
            registration_timestamp: 1234567890, prev_block_digest: block_170_hash, pow: 4295032833,
        },
        'unexpected status for block 171'
    );
}

#[test]
fn test_same_height_registration() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1728969824);

    // Block 865699 (first version)
    let block_865699_hash_1 = hex_to_hash_rev(
        "00000000000000000002648ba35429c4e46e38d5261331bbddd7244baf94d515"
    );
    let block_865699_1: BlockHeader = BlockHeaderTrait::new(
        632832000_u32,
        hex_to_hash_rev("000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"),
        hex_to_hash_rev("c491a795a7e3e7286426c15a623e03a80f31cf75fca08b31eb6a325cfe17b5e2"),
        1728969824_u32,
        0x17030ecd_u32,
        2662381191,
    );

    // Block 865699 (second version, canonical chain)
    let block_865699_hash_2 = hex_to_hash_rev(
        "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
    );
    let block_865699_2: BlockHeader = BlockHeaderTrait::new(
        905969664_u32,
        hex_to_hash_rev("000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"),
        hex_to_hash_rev("92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"),
        1728969853_u32,
        0x17030ecd_u32,
        3760750539,
    );

    // Register both blocks
    let block_headers: Array<BlockHeader> = array![block_865699_1, block_865699_2];
    utu.register_blocks(block_headers.span());

    // Check status of the first block
    let status_1 = utu.get_status(block_865699_hash_1);
    assert(
        status_1 == BlockStatus {
            registration_timestamp: 1728969824,
            prev_block_digest: hex_to_hash_rev(
                "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
            ),
            pow: 395356030850084270690399,
        },
        'unexpected status for block 1'
    );

    // Check status of the second block
    let status_2 = utu.get_status(block_865699_hash_2);
    assert(
        status_2 == BlockStatus {
            registration_timestamp: 1728969824,
            prev_block_digest: hex_to_hash_rev(
                "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
            ),
            pow: 395356030850084270690399,
        },
        'unexpected status for block 2'
    );
}
