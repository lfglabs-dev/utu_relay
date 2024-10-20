pub mod utu_relay;
pub mod interfaces;
pub mod bitcoin {
    pub mod transactions {
        // pub mod merkle_root;
        pub mod coinbase;
    }
    pub mod block;
    pub mod block_height;
}
pub mod utils {
    pub mod hex;
    pub mod hash;
    pub mod numeric;
    pub mod double_sha256;
    pub mod pow2;
}
#[cfg(test)]
mod tests {
    mod utils;
    mod blocks_registration;
    mod fork_resolutions;
}
