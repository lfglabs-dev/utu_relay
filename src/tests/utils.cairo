use crate::{interfaces::{BlockStatus, IUtuRelayDispatcher, IUtuRelayDispatcherTrait}};
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use utils::hash::Digest;


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

    // Deploy with empty constructor
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    let dispatcher = IUtuRelayDispatcher { contract_address };

    // Initialize the contract with owner
    let owner: ContractAddress = contract_address_const::<'owner'>();
    dispatcher.initialize(owner);

    dispatcher
}
