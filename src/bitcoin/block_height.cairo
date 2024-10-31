use crate::interfaces::HeightProof;
use crate::bitcoin::coinbase::get_coinbase_data;
use utils::double_sha256::double_sha256_parent;

/// Returns the block height given a block header, coinbase raw data, and an array of transaction
/// hashes.
/// Assumes the coinbase transaction is always the first transaction.
pub fn get_block_height(height_proof: @HeightProof) -> u64 {
    // Get coinbase data
    let coinbase_data = get_coinbase_data(height_proof.coinbase_raw_tx);

    let mut merkle_root = coinbase_data.tx_id;
    let mut tx_hashes = *height_proof.merkle_branch;
    loop {
        match tx_hashes.pop_front() {
            Option::Some(hash) => { merkle_root = double_sha256_parent(@merkle_root, hash); },
            Option::None => { break; }
        }
    };

    // Verify the merkle root
    assert(merkle_root == *height_proof.header.merkle_root_hash, 'Invalid merkle root');

    // Return the block height from coinbase data
    coinbase_data.height
}

#[cfg(test)]
mod tests {
    use super::get_block_height;
    use crate::interfaces::HeightProof;
    use crate::bitcoin::block::BlockHeaderTrait;
    use utils::hex::{from_hex, hex_to_hash_rev};

    #[test]
    fn test_get_block_height() {
        // Updated Block header data for block 227_836
        let header = BlockHeaderTrait::new(
            2,
            hex_to_hash_rev("00000000000001aa077d7aa84c532a4d69bdbff519609d1da0835261b7a74eb6"),
            hex_to_hash_rev("38a2518423d8ea76e716d1dc86d742b9e7f3febda7bf9a3e18bcd6c8ad55ff45"),
            1364140204,
            0x1a02816e,
            30275792,
        );

        // Coinbase transaction raw data (same as in the coinbase test)
        let coinbase_tx_raw_data = from_hex(
            "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2703fc7903062f503253482f04ac204f510858029a11000003550d3363646164312f736c7573682f0000000001207e6295000000001976a914e285a29e0704004d4e95dbb7c57a98563d9fb2eb88ac00000000"
        );

        // Transaction hashes (excluding the coinbase transaction)
        let tx_hashes = array![
            hex_to_hash_rev("263b1f316ed3a8080871ddedb12cbed139596ca99e3e1468c3cc72f37ee6acef"),
            hex_to_hash_rev("f87ddd6dbe85bd1d6a2392e1dd8b2ed11d4123d15d766e4628367dd177b809ee"),
            hex_to_hash_rev("e31c5f7950ca8dd3735ec097607a322bc721a9d2d92c0e992f5e7c9bdb91d73e"),
            hex_to_hash_rev("8083b63de604e4f8cc222937c2bcd8f7dd3a5f11700cb4bac17b844153999f9a"),
            hex_to_hash_rev("a44d18ffeb927a17f560463423c768eef3fa9bc716b119359df94fa6650fb80c"),
            hex_to_hash_rev("d1bbabfc237658cc7e97d1070e5d8dac45447e324ad6c6ac1f1e9451637d9c83"),
            hex_to_hash_rev("0b62547bbd044eab383bca97898d5616bd3bb38568bc8c9360fb37c6607a8536"),
        ];

        let height_proof = HeightProof {
            header: header, coinbase_raw_tx: coinbase_tx_raw_data, merkle_branch: tx_hashes.span()
        };
        let block_height = get_block_height(@height_proof);
        assert(block_height == 227_836, 'Incorrect block height');
    }
}
