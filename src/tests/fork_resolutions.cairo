use super::super::interfaces::IUtuRelayDispatcherTrait;
use crate::{
    interfaces::BlockStatus, utils::{hex::hex_to_hash_rev, hash::Digest},
    bitcoin::block::{BlockHeader, HumanReadableBlockHeader},
    tests::utils::{deploy_utu, BlockStatusIntoSpan, DigestIntoSpan},
};
use snforge_std::{start_cheat_block_timestamp, store, load, map_entry_address};

#[test]
fn test_replacing_by_longer_chain() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1_728_969_360);

    // Block 865_698
    let block_865_698_hash = hex_to_hash_rev(
        "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
    );
    let block_865_698: BlockHeader = HumanReadableBlockHeader {
        version: 582_238_208_u32,
        prev_block_hash: hex_to_hash_rev(
            "0000000000000000000135e8b5214c6de06ad988280816ce0daa1d92317c4904"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "219394ee994ef9dda390b34d6ef8d7fb3e24a05b2c29f02c1d7839aa6c154787"
        ),
        time: 1_728_969_360_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_876_725_546,
    }
        .into();

    // Block 865_699 (first version)
    let block_865_699_hash_1 = hex_to_hash_rev(
        "00000000000000000002648ba35429c4e46e38d5261331bbddd7244baf94d515"
    );
    let block_865_699_1: BlockHeader = HumanReadableBlockHeader {
        version: 632_832_000_u32,
        prev_block_hash: hex_to_hash_rev(
            "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "c491a795a7e3e7286426c15a623e03a80f31cf75fca08b31eb6a325cfe17b5e2"
        ),
        time: 1_728_969_824_u32,
        bits: 0x17030ecd_u32,
        nonce: 2_662_381_191,
    }
        .into();

    // Block 865_699 (second version, canonical chain)
    let block_865_699_hash_2 = hex_to_hash_rev(
        "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
    );
    let block_865_699_2: BlockHeader = HumanReadableBlockHeader {
        version: 905_969_664_u32,
        prev_block_hash: hex_to_hash_rev(
            "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"
        ),
        time: 1_728_969_853_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_760_750_539,
    }
        .into();

    // Block 865_700 (canonical chain)
    let block_865_700_hash = hex_to_hash_rev(
        "00000000000000000002a82a6dee77c45ecd5a072a6ad9fe31d818ff62f0d16b"
    );
    let block_865_700: BlockHeader = HumanReadableBlockHeader {
        version: 873_521_152_u32,
        prev_block_hash: hex_to_hash_rev(
            "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "2c5b149489af4585aefd2e8954de51ea461e2ebfb0b15ecf88aa1e94d276c997"
        ),
        time: 1_728_970_451_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_606_011_432,
    }
        .into();

    // Register all blocks
    let block_headers: Array<BlockHeader> = array![
        block_865_698, block_865_699_1, block_865_699_2, block_865_700
    ];
    utu.register_blocks(block_headers.span());

    // this should set the chain to an orphan block
    utu.set_main_chain(865_698, 865_699, block_865_699_hash_1);
    let orphan_digest = utu.get_block(865_699);
    assert(orphan_digest == block_865_699_hash_1, 'wrong orphan digest');

    // then this should correct it because the canonical chain is stronger
    utu.set_main_chain(865_698, 865_700, block_865_700_hash);
    let updated_block_digest = utu.get_block(865_699);
    assert(updated_block_digest == block_865_699_hash_2, 'wrong replaced digest');

    assert(utu.get_block(865_698) == block_865_698_hash, 'wrong first block');
    assert(utu.get_block(865_700) == block_865_700_hash, 'wrong last block');
}


#[test]
#[should_panic(expected: "Main chain has a stronger cpow than your proposed fork last block pow.")]
fn test_replacing_by_shorter_chain() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1_728_969_360);

    // Block 865_698
    let block_865_698: BlockHeader = HumanReadableBlockHeader {
        version: 582_238_208_u32,
        prev_block_hash: hex_to_hash_rev(
            "0000000000000000000135e8b5214c6de06ad988280816ce0daa1d92317c4904"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "219394ee994ef9dda390b34d6ef8d7fb3e24a05b2c29f02c1d7839aa6c154787"
        ),
        time: 1_728_969_360_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_876_725_546,
    }
        .into();

    // Block 865_699 (first version)
    let block_865_699_hash_1 = hex_to_hash_rev(
        "00000000000000000002648ba35429c4e46e38d5261331bbddd7244baf94d515"
    );
    let block_865_699_1: BlockHeader = HumanReadableBlockHeader {
        version: 632_832_000_u32,
        prev_block_hash: hex_to_hash_rev(
            "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "c491a795a7e3e7286426c15a623e03a80f31cf75fca08b31eb6a325cfe17b5e2"
        ),
        time: 1_728_969_824_u32,
        bits: 0x17030ecd_u32,
        nonce: 2_662_381_191,
    }
        .into();

    // Block 865_699 (second version, canonical chain)
    let block_865_699_2: BlockHeader = HumanReadableBlockHeader {
        version: 905_969_664_u32,
        prev_block_hash: hex_to_hash_rev(
            "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"
        ),
        time: 1_728_969_853_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_760_750_539,
    }
        .into();

    // Block 865_700 (canonical chain)
    let block_865_700_hash = hex_to_hash_rev(
        "00000000000000000002a82a6dee77c45ecd5a072a6ad9fe31d818ff62f0d16b"
    );
    let block_865_700: BlockHeader = HumanReadableBlockHeader {
        version: 873_521_152_u32,
        prev_block_hash: hex_to_hash_rev(
            "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "2c5b149489af4585aefd2e8954de51ea461e2ebfb0b15ecf88aa1e94d276c997"
        ),
        time: 1_728_970_451_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_606_011_432,
    }
        .into();

    // Register all blocks
    let block_headers: Array<BlockHeader> = array![
        block_865_698, block_865_699_1, block_865_699_2, block_865_700
    ];
    utu.register_blocks(block_headers.span());

    // we set the main chain to the stronger canonical chain
    utu.set_main_chain(865_698, 865_700, block_865_700_hash);

    // then we try to update to an orphan block
    utu.set_main_chain(865_698, 865_699, block_865_699_hash_1);
    let orphan_digest = utu.get_block(865_699);
    assert(orphan_digest == block_865_699_hash_1, 'wrong orphan digest');
}


#[test]
#[should_panic(expected: "Main chain has a stronger cpow than your proposed fork last block pow.")]
fn test_replacing_by_equal_chain() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1_728_969_360);

    // Block 865_698
    let block_865_698: BlockHeader = HumanReadableBlockHeader {
        version: 582_238_208_u32,
        prev_block_hash: hex_to_hash_rev(
            "0000000000000000000135e8b5214c6de06ad988280816ce0daa1d92317c4904"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "219394ee994ef9dda390b34d6ef8d7fb3e24a05b2c29f02c1d7839aa6c154787"
        ),
        time: 1_728_969_360_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_876_725_546,
    }
        .into();

    // Block 865_699 (first version)
    let block_865_699_hash_1 = hex_to_hash_rev(
        "00000000000000000002648ba35429c4e46e38d5261331bbddd7244baf94d515"
    );
    let block_865_699_1: BlockHeader = HumanReadableBlockHeader {
        version: 632_832_000_u32,
        prev_block_hash: hex_to_hash_rev(
            "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "c491a795a7e3e7286426c15a623e03a80f31cf75fca08b31eb6a325cfe17b5e2"
        ),
        time: 1_728_969_824_u32,
        bits: 0x17030ecd_u32,
        nonce: 2_662_381_191,
    }
        .into();

    // Block 865_699 (second version, canonical chain)
    let block_865_699_hash_2 = hex_to_hash_rev(
        "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
    );
    let block_865_699_2: BlockHeader = HumanReadableBlockHeader {
        version: 905_969_664_u32,
        prev_block_hash: hex_to_hash_rev(
            "000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"
        ),
        merkle_root_hash: hex_to_hash_rev(
            "92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"
        ),
        time: 1_728_969_853_u32,
        bits: 0x17030ecd_u32,
        nonce: 3_760_750_539,
    }
        .into();

    // Register all blocks
    let block_headers: Array<BlockHeader> = array![block_865_698, block_865_699_1, block_865_699_2];
    utu.register_blocks(block_headers.span());

    // we set the main chain to the canonical chain
    utu.set_main_chain(865_698, 865_700, block_865_699_hash_2);

    // then we try to update to an orphan block (should be refused so that you can't update back and
    // forth)
    utu.set_main_chain(865_698, 865_699, block_865_699_hash_1);
    let orphan_digest = utu.get_block(865_699);
    assert(orphan_digest == block_865_699_hash_1, 'wrong orphan digest');
}

#[test]
//#[should_panic(expected: "Main chain has a single block stronger than your proposed fork.")]
fn test_replacing_by_longer_but_weaker_chain() {
    let utu = deploy_utu();
    // a random timestamp
    let registration_timestamp = 1_728_969_360;
    // we store a BlockStatus with hash 0x1 and pow 999_999

    let block1 = BlockStatus {
        registration_timestamp, prev_block_digest: 0x0_u256.into(), pow: 1_000,
    };
    let block1_digest: Digest = 0x1_u256.into();

    let block2a = BlockStatus {
        registration_timestamp, prev_block_digest: block1_digest, pow: 1_000,
    };
    let block2a_digest: Digest = 0x2a_u256.into();

    let block2b = BlockStatus {
        registration_timestamp, prev_block_digest: block1_digest, pow: 500,
    };
    let block2b_digest: Digest = 0x2b_u256.into();

    let block3a = BlockStatus {
        registration_timestamp, prev_block_digest: block2a_digest, pow: 999,
    };
    let block3a_digest: Digest = 0x3a_u256.into();

    let block3b = BlockStatus {
        registration_timestamp, prev_block_digest: block2b_digest, pow: 500,
    };
    let block3b_digest: Digest = 0x3b_u256.into();

    let block4 = BlockStatus {
        registration_timestamp, prev_block_digest: block3b_digest, pow: 500,
    };
    let block4_digest: Digest = 0x4_u256.into();

    store(
        utu.contract_address,
        map_entry_address(selector!("blocks"), block1_digest.into()),
        block1.into()
    );

    store(
        utu.contract_address,
        map_entry_address(selector!("blocks"), block2a_digest.into()),
        block2a.into()
    );

    store(
        utu.contract_address,
        map_entry_address(selector!("blocks"), block2b_digest.into()),
        block2b.into()
    );

    store(
        utu.contract_address,
        map_entry_address(selector!("blocks"), block3a_digest.into()),
        block3a.into()
    );

    store(
        utu.contract_address,
        map_entry_address(selector!("blocks"), block3b_digest.into()),
        block3b.into()
    );

    store(
        utu.contract_address,
        map_entry_address(selector!("blocks"), block4_digest.into()),
        block4.into()
    );
    // we now have 2 chains:
    // a) [ 0x1, 0x2a, 0x3a ]
    // b) [ 0x1, 0x2b, 0x3b, 0x4]
    // where a[1:] cpow equals 1999 > 1500 for b[1:] even though b is longer

    let _block1_status = utu.get_status(block1_digest);
    let _loaded_status = load(
        utu.contract_address, map_entry_address(selector!("blocks"), block1_digest.into()), 10
    );
    // println!("block1_status: {:?}", block1_status);
// println!("loaded_status: {:?}", loaded_status);
//utu.set_main_chain(1, 3, block2a_digest);
//utu.set_main_chain(1, 4, block2b_digest);
}
