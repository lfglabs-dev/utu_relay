use starknet::storage_access::{Store, StorageBaseAddress};
use utils::hash::Digest;

// todo: pack the felts to save on storage
pub impl DigestStore of starknet::Store<Digest> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> starknet::SyscallResult<Digest> {
        match Store::<[u32; 8]>::read(address_domain, base) {
            Result::Ok(value) => Result::Ok(Digest { value }),
            Result::Err(err) => Result::Err(err),
        }
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Digest
    ) -> starknet::SyscallResult<()> {
        Store::<[u32; 8]>::write(address_domain, base, value.value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8
    ) -> starknet::SyscallResult<Digest> {
        match Store::<[u32; 8]>::read_at_offset(address_domain, base, offset) {
            Result::Ok(value) => Result::Ok(Digest { value }),
            Result::Err(err) => Result::Err(err),
        }
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8, value: Digest
    ) -> starknet::SyscallResult<()> {
        Store::<[u32; 8]>::write_at_offset(address_domain, base, offset, value.value)
    }

    fn size() -> u8 {
        Store::<[u32; 8]>::size()
    }
}
