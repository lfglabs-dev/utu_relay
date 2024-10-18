/// Calculate 2 raised to the power of the given exponent
/// using a pre-computed lookup table
/// # Arguments
/// * `exponent` - The exponent to raise 2 to
/// # Returns
/// * `u128` - The result of 2^exponent
/// # Panics
/// * If `exponent` is greater than 127 (out of the supported range)
pub fn pow2_u128(exponent: u32) -> u128 {
    let results: [u128; 128] = [
        0x1,
        0x2,
        0x4,
        0x8,
        0x10,
        0x20,
        0x40,
        0x80,
        0x100,
        0x200,
        0x400,
        0x800,
        0x1000,
        0x2000,
        0x4000,
        0x8000,
        0x10000,
        0x20000,
        0x40000,
        0x80000,
        0x100000,
        0x200000,
        0x400000,
        0x800000,
        0x1000000,
        0x2000000,
        0x4000000,
        0x8000000,
        0x10000000,
        0x20000000,
        0x40000000,
        0x80000000,
        0x100000000,
        0x200000000,
        0x400000000,
        0x800000000,
        0x1000000000,
        0x2000000000,
        0x4000000000,
        0x8000000000,
        0x10000000000,
        0x20000000000,
        0x40000000000,
        0x80000000000,
        0x100000000000,
        0x200000000000,
        0x400000000000,
        0x800000000000,
        0x1000000000000,
        0x2000000000000,
        0x4000000000000,
        0x8000000000000,
        0x10000000000000,
        0x20000000000000,
        0x40000000000000,
        0x80000000000000,
        0x100000000000000,
        0x200000000000000,
        0x400000000000000,
        0x800000000000000,
        0x1000000000000000,
        0x2000000000000000,
        0x4000000000000000,
        0x8000000000000000,
        0x10000000000000000,
        0x20000000000000000,
        0x40000000000000000,
        0x80000000000000000,
        0x100000000000000000,
        0x200000000000000000,
        0x400000000000000000,
        0x800000000000000000,
        0x1000000000000000000,
        0x2000000000000000000,
        0x4000000000000000000,
        0x8000000000000000000,
        0x10000000000000000000,
        0x20000000000000000000,
        0x40000000000000000000,
        0x80000000000000000000,
        0x100000000000000000000,
        0x200000000000000000000,
        0x400000000000000000000,
        0x800000000000000000000,
        0x1000000000000000000000,
        0x2000000000000000000000,
        0x4000000000000000000000,
        0x8000000000000000000000,
        0x10000000000000000000000,
        0x20000000000000000000000,
        0x40000000000000000000000,
        0x80000000000000000000000,
        0x100000000000000000000000,
        0x200000000000000000000000,
        0x400000000000000000000000,
        0x800000000000000000000000,
        0x1000000000000000000000000,
        0x2000000000000000000000000,
        0x4000000000000000000000000,
        0x8000000000000000000000000,
        0x10000000000000000000000000,
        0x20000000000000000000000000,
        0x40000000000000000000000000,
        0x80000000000000000000000000,
        0x100000000000000000000000000,
        0x200000000000000000000000000,
        0x400000000000000000000000000,
        0x800000000000000000000000000,
        0x1000000000000000000000000000,
        0x2000000000000000000000000000,
        0x4000000000000000000000000000,
        0x8000000000000000000000000000,
        0x10000000000000000000000000000,
        0x20000000000000000000000000000,
        0x40000000000000000000000000000,
        0x80000000000000000000000000000,
        0x100000000000000000000000000000,
        0x200000000000000000000000000000,
        0x400000000000000000000000000000,
        0x800000000000000000000000000000,
        0x1000000000000000000000000000000,
        0x2000000000000000000000000000000,
        0x4000000000000000000000000000000,
        0x8000000000000000000000000000000,
        0x10000000000000000000000000000000,
        0x20000000000000000000000000000000,
        0x40000000000000000000000000000000,
        0x80000000000000000000000000000000
    ];
    *results.span()[exponent]
}

#[cfg(test)]
mod tests {
    use super::pow2_u128;

    #[test]
    fn test_fast_pow2_u128() {
        assert(pow2_u128(0) == 1, '2^0 should be 1');
        assert(pow2_u128(18) == 262144, '2^18 should be 262144');
        assert(pow2_u128(127) == 170141183460469231731687303715884105728, '2^127 correct');
    }
}
