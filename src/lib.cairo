pub mod utu_relay;
pub mod interfaces;
pub mod bitcoin {
    pub mod coinbase;
    pub mod block;
    pub mod block_height;
}
pub mod utils {
    pub mod digest;
    pub mod pow2;
}
#[cfg(test)]
mod tests {
    mod utils;
    mod safety;
    mod blocks_registration;
    mod fork_resolutions;
}
