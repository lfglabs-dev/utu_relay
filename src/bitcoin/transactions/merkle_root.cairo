use crate::utils::hash::Digest;
use crate::utils::double_sha256::double_sha256_parent;

/// Computes the Merkle root from a transaction hash and its siblings.
///
/// # Arguments
/// * `tx_hash` - The transaction hash as a Digest
/// * `siblings` - An array of tuples (Digest, bool), where the bool indicates if the sibling is on
/// the right
///
/// # Returns
/// The computed Merkle root as a Digest
pub fn compute_merkle_root(tx_hash: Digest, siblings: Array<(Digest, bool)>) -> Digest {
    let mut current_hash = tx_hash;

    // Iterate through all siblings
    let mut i = 0;
    loop {
        if i == siblings.len() {
            break;
        }

        let (sibling, is_right) = *siblings.at(i);

        // Concatenate current_hash and sibling based on the order
        current_hash =
            if is_right {
                double_sha256_parent(@current_hash, @sibling)
            } else {
                double_sha256_parent(@sibling, @current_hash)
            };

        i += 1;
    };

    current_hash
}

#[cfg(test)]
mod tests {
    use super::compute_merkle_root;
    use crate::utils::hex::{hex_to_hash_rev};

    #[test]
    fn test_compute_merkle_root() {
        // Test data
        let tx_hash = hex_to_hash_rev(
            "0f3601a5da2f516fa9d3f80c9bf6e530f1afb0c90da73e8f8ad0630c5483afe5"
        );
        let siblings = array![
            (
                hex_to_hash_rev("eface67ef372ccc368143e9ea96c5939d1be2cb1eddd710808a8d36e311f3b26"),
                true
            ),
            (
                hex_to_hash_rev("ee09b877d17d3628466e765dd123411dd12e8bdde192236a1dbd85be6ddd7df8"),
                true
            ),
            (
                hex_to_hash_rev("3ed791db9b7c5e2f990e2cd9d2a921c72b327a6097c05e73d38dca50795f1ce3"),
                true
            ),
            (
                hex_to_hash_rev("9a9f995341847bc1bab40c70115f3addf7d8bcc2372922ccf8e404e63db68380"),
                true
            ),
        ];

        let expected_merkle_root = hex_to_hash_rev(
            "38a2518423d8ea76e716d1dc86d742b9e7f3febda7bf9a3e18bcd6c8ad55ff45"
        );
        let computed_merkle_root = compute_merkle_root(tx_hash, siblings);

        assert(computed_merkle_root == expected_merkle_root, 'Incorrect Merkle root');
    }
}
