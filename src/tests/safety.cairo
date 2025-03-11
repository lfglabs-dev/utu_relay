use super::super::interfaces::{HeightProof, IUtuRelayDispatcherTrait};
use crate::{
    bitcoin::block::{BlockHeader, BlockHeaderTrait, BlockHashImpl},
    tests::utils::{deploy_utu, BlockStatusIntoSpan, DigestIntoSpan},
};
use utils::{hex::{from_hex, hex_to_hash_rev}};
use snforge_std::start_cheat_block_timestamp;
use crate::utils::numeric::u32_byte_reverse;

#[test]
fn test_is_safe() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1_728_969_360);

    let block_865_698: BlockHeader = BlockHeaderTrait::new(
        582_238_208_u32,
        hex_to_hash_rev("0000000000000000000135e8b5214c6de06ad988280816ce0daa1d92317c4904"),
        hex_to_hash_rev("219394ee994ef9dda390b34d6ef8d7fb3e24a05b2c29f02c1d7839aa6c154787"),
        1_728_969_360_u32,
        0x17030ecd_u32,
        3_876_725_546,
    );

    let block_865_699_hash = hex_to_hash_rev(
        "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
    );
    let block_865_699: BlockHeader = BlockHeaderTrait::new(
        905_969_664_u32,
        hex_to_hash_rev("000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"),
        hex_to_hash_rev("92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"),
        1_728_969_853_u32,
        0x17030ecd_u32,
        3_760_750_539,
    );

    // Register only canonical chain blocks
    let block_headers: Array<BlockHeader> = array![block_865_698, block_865_699];
    utu.register_blocks(block_headers.span());

    let coinbase_tx_raw_data = from_hex(
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5603a2350d194d696e656420627920416e74506f6f6c20e2002a00b4747806fabe6d6d710d04d1ea50a50e6329e2fa1ab865fa16083c12ae90926ee2d687d78e64243210000000000000000000e2701102000000000000ffffffff05220200000000000017a91442402a28dd61f2718a4b27ae72a4791d5bbdade787aca64c130000000017a9145249bdf2c131d43995cff42e8feee293f79297a8870000000000000000266a24aa21a9ed70918c35041817b2ce38010673f3420b25a34c0480a9e53a280f7eb1b0ccffdc00000000000000002f6a2d434f52450164db24a662e20bbdf72d1cc6e973dbb2d12897d54e3ecda72cb7961caa4b541b1e322bcfe0b5a03000000000000000002b6a2952534b424c4f434b3a900671964dfd53207639c814270d32fbb670620e4ddd8821dd3d5c100067a1e300000000"
    );
    let merkle_branch = [
        hex_to_hash_rev("1a523b9d1db74158daea077276b1cd3f3eac87cd685d136133d414d04d7f1aed"),
        hex_to_hash_rev("f3b0b4fced6987a1c9a5f2f70eb245585d02bf8579c4ec32d08faa88285738b7"),
        hex_to_hash_rev("ea38f07950ea6fd120699c1b77578a8e8f922d4b6640345f5ac264d11b4598da"),
        hex_to_hash_rev("4385664ebdd2988d5293167646a791d4ec3e165be0012424c70a842270bba968"),
        hex_to_hash_rev("fa19b3bda922723a31ea7d1cfe474cd9f52a8d70b28c481c6567f92581b4d0ab"),
        hex_to_hash_rev("47f2f41cdede72662413e02b0a646b3c5f5b4f2629a81f83ad903db78302ef19"),
        hex_to_hash_rev("03c644a689e264ed605517e22929b7c6e972d2ad2e942bfeaea50cae8f3a598d"),
        hex_to_hash_rev("5041fe4b358c487b01cec6b2ba8780d831465bcae3b748f7e2377915a58ee0f4"),
        hex_to_hash_rev("67a27f730a4d4ac69937afb8be7464564710fa2ddcbffc1cdc1cccd4543c6d36"),
        hex_to_hash_rev("7602d7c94c5f25b91937fc5ac1c4a3f2cffca3426ca1df7fa3fabd690755f46d"),
        hex_to_hash_rev("29c3f6ea6e559e9f03625061f89f405ab7341b32e1e3d3507de104c506e92af4"),
        hex_to_hash_rev("d9d0c63e9fdd9a4b278cb41c669405073988f75baaa7719fcda0650badc4b2a2"),
        hex_to_hash_rev("372d13ce7f696f978dbf135af7f3658df37126abf93c0996f92ff8f709081ef0")
    ];
    let height_proof = HeightProof {
        header: block_865_698,
        coinbase_raw_tx: coinbase_tx_raw_data,
        merkle_branch: merkle_branch.span()
    };

    // Update to canonical chain
    utu.update_canonical_chain(865_698, 865_699, block_865_699_hash, Option::Some(height_proof));

    // Advance in time by 2 hour
    let current_time = 1_728_969_360 + 2 * 3600;
    start_cheat_block_timestamp(utu.contract_address, current_time);

    // Assert block is safe: More than 1M of cumulated PoW & at least one hour of registration time
    utu.assert_safe(865_698, block_865_698.hash(), 1_000_000, 3600);
    // Ensures block was not pre computed
    let block_time = u32_byte_reverse(block_865_698.time).into();
    assert(block_time <= current_time, 'Block comes from the future.');
}


#[test]
#[should_panic(expected: "Cumulative PoW is not enough to guarantee safety.")]
fn test_unsafe_pow() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1_728_969_360);

    let block_865_698: BlockHeader = BlockHeaderTrait::new(
        582_238_208_u32,
        hex_to_hash_rev("0000000000000000000135e8b5214c6de06ad988280816ce0daa1d92317c4904"),
        hex_to_hash_rev("219394ee994ef9dda390b34d6ef8d7fb3e24a05b2c29f02c1d7839aa6c154787"),
        1_728_969_360_u32,
        0x17030ecd_u32,
        3_876_725_546,
    );

    let block_865_699_hash = hex_to_hash_rev(
        "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
    );
    let block_865_699: BlockHeader = BlockHeaderTrait::new(
        905_969_664_u32,
        hex_to_hash_rev("000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"),
        hex_to_hash_rev("92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"),
        1_728_969_853_u32,
        0x17030ecd_u32,
        3_760_750_539,
    );

    // Register only canonical chain blocks
    let block_headers: Array<BlockHeader> = array![block_865_698, block_865_699];
    utu.register_blocks(block_headers.span());

    let coinbase_tx_raw_data = from_hex(
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5603a2350d194d696e656420627920416e74506f6f6c20e2002a00b4747806fabe6d6d710d04d1ea50a50e6329e2fa1ab865fa16083c12ae90926ee2d687d78e64243210000000000000000000e2701102000000000000ffffffff05220200000000000017a91442402a28dd61f2718a4b27ae72a4791d5bbdade787aca64c130000000017a9145249bdf2c131d43995cff42e8feee293f79297a8870000000000000000266a24aa21a9ed70918c35041817b2ce38010673f3420b25a34c0480a9e53a280f7eb1b0ccffdc00000000000000002f6a2d434f52450164db24a662e20bbdf72d1cc6e973dbb2d12897d54e3ecda72cb7961caa4b541b1e322bcfe0b5a03000000000000000002b6a2952534b424c4f434b3a900671964dfd53207639c814270d32fbb670620e4ddd8821dd3d5c100067a1e300000000"
    );
    let merkle_branch = [
        hex_to_hash_rev("1a523b9d1db74158daea077276b1cd3f3eac87cd685d136133d414d04d7f1aed"),
        hex_to_hash_rev("f3b0b4fced6987a1c9a5f2f70eb245585d02bf8579c4ec32d08faa88285738b7"),
        hex_to_hash_rev("ea38f07950ea6fd120699c1b77578a8e8f922d4b6640345f5ac264d11b4598da"),
        hex_to_hash_rev("4385664ebdd2988d5293167646a791d4ec3e165be0012424c70a842270bba968"),
        hex_to_hash_rev("fa19b3bda922723a31ea7d1cfe474cd9f52a8d70b28c481c6567f92581b4d0ab"),
        hex_to_hash_rev("47f2f41cdede72662413e02b0a646b3c5f5b4f2629a81f83ad903db78302ef19"),
        hex_to_hash_rev("03c644a689e264ed605517e22929b7c6e972d2ad2e942bfeaea50cae8f3a598d"),
        hex_to_hash_rev("5041fe4b358c487b01cec6b2ba8780d831465bcae3b748f7e2377915a58ee0f4"),
        hex_to_hash_rev("67a27f730a4d4ac69937afb8be7464564710fa2ddcbffc1cdc1cccd4543c6d36"),
        hex_to_hash_rev("7602d7c94c5f25b91937fc5ac1c4a3f2cffca3426ca1df7fa3fabd690755f46d"),
        hex_to_hash_rev("29c3f6ea6e559e9f03625061f89f405ab7341b32e1e3d3507de104c506e92af4"),
        hex_to_hash_rev("d9d0c63e9fdd9a4b278cb41c669405073988f75baaa7719fcda0650badc4b2a2"),
        hex_to_hash_rev("372d13ce7f696f978dbf135af7f3658df37126abf93c0996f92ff8f709081ef0")
    ];
    let height_proof = HeightProof {
        header: block_865_698,
        coinbase_raw_tx: coinbase_tx_raw_data,
        merkle_branch: merkle_branch.span()
    };

    // Update to canonical chain
    utu.update_canonical_chain(865_698, 865_699, block_865_699_hash, Option::Some(height_proof));

    // Advance in time by 2 hour
    let current_time = 1_728_969_360 + 2 * 3600;
    start_cheat_block_timestamp(utu.contract_address, current_time);

    // Assert block is safe: More than 1M of cumulated PoW & at least one hour of registration time
    utu.assert_safe(865_698, block_865_698.hash(), 100000000000000000000000000000000, 3600);
}


#[test]
#[should_panic(expected: "Block registration age is below minimum required.")]
fn test_unsafe_registration() {
    let utu = deploy_utu();

    start_cheat_block_timestamp(utu.contract_address, 1_728_969_360);

    let block_865_698: BlockHeader = BlockHeaderTrait::new(
        582_238_208_u32,
        hex_to_hash_rev("0000000000000000000135e8b5214c6de06ad988280816ce0daa1d92317c4904"),
        hex_to_hash_rev("219394ee994ef9dda390b34d6ef8d7fb3e24a05b2c29f02c1d7839aa6c154787"),
        1_728_969_360_u32,
        0x17030ecd_u32,
        3_876_725_546,
    );

    let block_865_699_hash = hex_to_hash_rev(
        "00000000000000000000e7a78ccc708a62c6e04e8a4b5ef3bf4abd7a4c1b5b10"
    );
    let block_865_699: BlockHeader = BlockHeaderTrait::new(
        905_969_664_u32,
        hex_to_hash_rev("000000000000000000012bc4e973e18e17b9980ba5b6fe545a5f05e0e222828c"),
        hex_to_hash_rev("92888eb107c908635e5b5061ed2ac76744ba875661cfb1b77fe39f4c8dc60b11"),
        1_728_969_853_u32,
        0x17030ecd_u32,
        3_760_750_539,
    );

    // Register only canonical chain blocks
    let block_headers: Array<BlockHeader> = array![block_865_698, block_865_699];
    utu.register_blocks(block_headers.span());

    let coinbase_tx_raw_data = from_hex(
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5603a2350d194d696e656420627920416e74506f6f6c20e2002a00b4747806fabe6d6d710d04d1ea50a50e6329e2fa1ab865fa16083c12ae90926ee2d687d78e64243210000000000000000000e2701102000000000000ffffffff05220200000000000017a91442402a28dd61f2718a4b27ae72a4791d5bbdade787aca64c130000000017a9145249bdf2c131d43995cff42e8feee293f79297a8870000000000000000266a24aa21a9ed70918c35041817b2ce38010673f3420b25a34c0480a9e53a280f7eb1b0ccffdc00000000000000002f6a2d434f52450164db24a662e20bbdf72d1cc6e973dbb2d12897d54e3ecda72cb7961caa4b541b1e322bcfe0b5a03000000000000000002b6a2952534b424c4f434b3a900671964dfd53207639c814270d32fbb670620e4ddd8821dd3d5c100067a1e300000000"
    );
    let merkle_branch = [
        hex_to_hash_rev("1a523b9d1db74158daea077276b1cd3f3eac87cd685d136133d414d04d7f1aed"),
        hex_to_hash_rev("f3b0b4fced6987a1c9a5f2f70eb245585d02bf8579c4ec32d08faa88285738b7"),
        hex_to_hash_rev("ea38f07950ea6fd120699c1b77578a8e8f922d4b6640345f5ac264d11b4598da"),
        hex_to_hash_rev("4385664ebdd2988d5293167646a791d4ec3e165be0012424c70a842270bba968"),
        hex_to_hash_rev("fa19b3bda922723a31ea7d1cfe474cd9f52a8d70b28c481c6567f92581b4d0ab"),
        hex_to_hash_rev("47f2f41cdede72662413e02b0a646b3c5f5b4f2629a81f83ad903db78302ef19"),
        hex_to_hash_rev("03c644a689e264ed605517e22929b7c6e972d2ad2e942bfeaea50cae8f3a598d"),
        hex_to_hash_rev("5041fe4b358c487b01cec6b2ba8780d831465bcae3b748f7e2377915a58ee0f4"),
        hex_to_hash_rev("67a27f730a4d4ac69937afb8be7464564710fa2ddcbffc1cdc1cccd4543c6d36"),
        hex_to_hash_rev("7602d7c94c5f25b91937fc5ac1c4a3f2cffca3426ca1df7fa3fabd690755f46d"),
        hex_to_hash_rev("29c3f6ea6e559e9f03625061f89f405ab7341b32e1e3d3507de104c506e92af4"),
        hex_to_hash_rev("d9d0c63e9fdd9a4b278cb41c669405073988f75baaa7719fcda0650badc4b2a2"),
        hex_to_hash_rev("372d13ce7f696f978dbf135af7f3658df37126abf93c0996f92ff8f709081ef0")
    ];
    let height_proof = HeightProof {
        header: block_865_698,
        coinbase_raw_tx: coinbase_tx_raw_data,
        merkle_branch: merkle_branch.span()
    };

    // Update to canonical chain
    utu.update_canonical_chain(865_698, 865_699, block_865_699_hash, Option::Some(height_proof));

    // Advance in time by half an hour
    let current_time = 1_728_969_360 + 1800;
    start_cheat_block_timestamp(utu.contract_address, current_time);

    // Assert block is safe: More one hour of registration time
    utu.assert_safe(865_698, block_865_698.hash(), 1000, 3600);
}
