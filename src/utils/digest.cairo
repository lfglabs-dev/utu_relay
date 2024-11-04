use starknet::storage_access::{Store, StorageBaseAddress};
use utils::hash::{Digest, U256IntoDigest, DigestIntoU256};

// todo: pack the felts to save on storage
pub impl DigestStore of starknet::Store<Digest> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> starknet::SyscallResult<Digest> {
        match Store::<felt252>::read(address_domain, base) {
            Result::Ok(value) => {
                let value_as_u256: u256 = value.into();
                Result::Ok(value_as_u256.into())
            },
            Result::Err(err) => Result::Err(err),
        }
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Digest
    ) -> starknet::SyscallResult<()> {
        let value_as_u256: u256 = value.into();
        Store::<felt252>::write(address_domain, base, value_as_u256.try_into().unwrap())
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8
    ) -> starknet::SyscallResult<Digest> {
        match Store::<felt252>::read_at_offset(address_domain, base, offset) {
            Result::Ok(value) => {
                let value_as_u256: u256 = value.into();
                Result::Ok(value_as_u256.into())
            },
            Result::Err(err) => Result::Err(err),
        }
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8, value: Digest
    ) -> starknet::SyscallResult<()> {
        let value_as_u256: u256 = value.into();
        Store::<
            felt252
        >::write_at_offset(address_domain, base, offset, value_as_u256.try_into().unwrap())
    }

    // Returns 1 since we store the Bitcoin hash (256 bits) as a single felt (251 bits).
    // This is possible because in Bitcoin mainnet, due to minimum difficulty requirements,
    // the first 32 bits of the hash are always zeros.
    fn size() -> u8 {
        // Store::<[u32; 8]>::size()
        1
    }
}
