use super::super::interfaces::{IUtuRelayDispatcherTrait, BlockStatus};
use crate::{
    utils::hex::hex_to_hash_rev, bitcoin::block::{BlockHeader, HumanReadableBlockHeader},
    tests::utils::deploy_utu
};
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

    let block_170: BlockHeader = HumanReadableBlockHeader {
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
    }
        .into();

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
            challenged_cpow: 0,
            pow: 4295032833,
        },
        'unexpected final status'
    );
}
