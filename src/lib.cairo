pub mod utu_relay;
pub mod interfaces;
pub mod bitcoin {
    pub mod block;
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
