use crate::interfaces::IUtuRelayDispatcher;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

pub fn deploy_utu() -> IUtuRelayDispatcher {
    let contract = declare("UtuRelay").unwrap().contract_class();
    let _owner: ContractAddress = contract_address_const::<'owner'>();

    let mut constructor_calldata = array![];
    let (contract_address, _constructor_returned_data) = contract
        .deploy(@constructor_calldata)
        .unwrap();

   IUtuRelayDispatcher { contract_address }
}
