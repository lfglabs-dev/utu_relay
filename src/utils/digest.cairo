use starknet::storage_access::{Store, StorageBaseAddress};
use utils::hash::Digest;

pub impl DigestStore of starknet::Store<Digest> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> starknet::SyscallResult<Digest> {
        Store::read(address_domain, base)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Digest
    ) -> starknet::SyscallResult<()> {
        Store::write(address_domain, base, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8
    ) -> starknet::SyscallResult<Digest> {
        Store::read_at_offset(address_domain, base, offset)
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8, value: Digest
    ) -> starknet::SyscallResult<()> {
        Store::write_at_offset(address_domain, base, offset, value)
    }

    fn size() -> u8 {
        Self::size()
    }
}
