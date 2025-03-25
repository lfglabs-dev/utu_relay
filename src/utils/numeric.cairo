use utils::hash::{Digest, DigestTrait};
use utils::sha256::{compute_sha256_byte_array, compute_sha256_u32_array};

/// Reverses the byte order of a `u32`.
///
/// This function takes a 32-bit unsigned integer and reverses the order of its bytes.
/// It is useful for converting between big-endian and little-endian formats.
pub fn u32_byte_reverse(word: u32) -> u32 {
    let byte0 = (word & 0x000000FF) * 0x1000000_u32;
    let byte1 = (word & 0x0000FF00) * 0x00000100_u32;
    let byte2 = (word & 0x00FF0000) / 0x00000100_u32;
    let byte3 = (word & 0xFF000000) / 0x1000000_u32;
    return byte0 + byte1 + byte2 + byte3;
}

/// Calculates double sha256 digest of bytes.
pub fn double_sha256_byte_array(bytes: @ByteArray) -> Digest {
    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_byte_array(bytes).span());

    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}

/// Calculates double sha256 digest of an array of full 4 byte words.
///
/// It's important that there are no trailing bytes, otherwise the
/// data will be truncated.
pub fn double_sha256_u32_array(words: Array<u32>) -> Digest {
    let mut input2: Array<u32> = array![];
    input2.append_span(compute_sha256_u32_array(words, 0, 0).span());


    DigestTrait::new(compute_sha256_u32_array(input2, 0, 0))
}