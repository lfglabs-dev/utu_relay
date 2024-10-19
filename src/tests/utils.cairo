use crate::{interfaces::{BlockStatus, IUtuRelayDispatcher}, utils::hash::Digest};
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

pub impl BlockStatusIntoSpan of Into<BlockStatus, Span<felt252>> {
    fn into(self: BlockStatus) -> Span<felt252> {
        let mut serialized_struct: Array<felt252> = array![];
        self.serialize(ref serialized_struct);
        serialized_struct.span()
    }
}

pub impl DigestIntoSpan of Into<Digest, Span<felt252>> {
    fn into(self: Digest) -> Span<felt252> {
        let mut serialized_struct: Array<felt252> = array![];
        self.serialize(ref serialized_struct);
        serialized_struct.span()
    }
}

pub fn deploy_utu() -> IUtuRelayDispatcher {
    let contract = declare("UtuRelay").unwrap().contract_class();
    let _owner: ContractAddress = contract_address_const::<'owner'>();

    let mut constructor_calldata = array![];
    let (contract_address, _constructor_returned_data) = contract
        .deploy(@constructor_calldata)
        .unwrap();

    IUtuRelayDispatcher { contract_address }
}
