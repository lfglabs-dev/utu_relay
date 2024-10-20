use crate::utils::{hash::Digest, double_sha256::double_sha256_byte_array};

pub struct CoinbaseData {
    pub tx_id: Digest,
    pub height: u64
}

/// Verifies if a transaction is a coinbase transaction and extracts its information.
/// This function only supports coinbase transactions from block 227_836 and onwards.
///
/// # Arguments
/// * `raw_tx` - The raw transaction data as a ByteArray
///
/// # Returns
/// A tuple containing:
/// * The transaction ID (Digest)
/// * The block height (u64)
///
/// # Panics
/// Panics if the transaction is not a valid coinbase transaction or if the coinbase data
/// doesn't seem to contain a block height. It is unlikely but possible that a pre BIP-34
/// coinbase data gets wrongly interpreted. Consider asserting the block version (>= 2).

pub fn get_coinbase_data(raw_tx: @ByteArray) -> CoinbaseData {
    let tx_id: Digest = double_sha256_byte_array(raw_tx);
    // would be zero for segwit transaction
    let input_count = raw_tx[4];
    if input_count != 1 {
        panic!("A coinbase transaction input count must be 1.");
    };
    // we then check this single input is transaction hash 0x0
    let mut prev_tx_i = 5;
    loop {
        if prev_tx_i == 37 {
            break;
        }
        if raw_tx[prev_tx_i] != 0 {
            panic!("The single coinbase input tx hash input must be 0x0.")
        };
        prev_tx_i += 1;
    };

    // Read the compactSize value starting at index 41, almost certainly in first branch
    let first_byte = raw_tx[41];
    // the first byte of coinbase data is a marker, then the next 3 bytes hold the block height
    let coinbase_height_start_index = if first_byte == 0xfd {
        44 // 2-byte varint
    } else if first_byte == 0xfe {
        46 // 4-byte varint
    } else if first_byte == 0xff {
        50 // 8-byte varint
    } else {
        42 // Single byte varint (default case)
    };

    if raw_tx[coinbase_height_start_index] != 0x3 {
        panic!(
            "Data-pushing opcode should be 0x3 until block 16,777,216 about 300 years from now."
        );
    }

    let height: u64 = ((raw_tx[coinbase_height_start_index + 1]).into())
        + ((raw_tx[coinbase_height_start_index + 2]).into() * 0x100)
        + ((raw_tx[coinbase_height_start_index + 3]).into() * 0x10000);

    CoinbaseData { tx_id, height }
}

#[cfg(test)]
mod tests {
    use crate::utils::hex::{from_hex, hex_to_hash_rev};
    use super::get_coinbase_data;

    #[test]
    fn test_get_coinbase_data() {
        // hex raw transaction of 0f3601a5da2f516fa9d3f80c9bf6e530f1afb0c90da73e8f8ad0630c5483afe5
        // which is the coinbase tx from block 227_836, the first one to include block height
        let coinbase_tx_raw_data = from_hex(
            "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2703fc7903062f503253482f04ac204f510858029a11000003550d3363646164312f736c7573682f0000000001207e6295000000001976a914e285a29e0704004d4e95dbb7c57a98563d9fb2eb88ac00000000"
        );
        let coinbase_data = get_coinbase_data(@coinbase_tx_raw_data);

        assert(
            coinbase_data
                .tx_id == hex_to_hash_rev(
                    "0f3601a5da2f516fa9d3f80c9bf6e530f1afb0c90da73e8f8ad0630c5483afe5"
                ),
            'Unexpected coinbase tx id'
        );

        assert(coinbase_data.height == 227_836, 'Unexpected block height');
    }
}
