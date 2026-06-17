use serde::{Deserialize, Serialize};

pub const DAEMON_ADDR: &str = "127.0.0.1:9090";

#[derive(Debug, Serialize, Deserialize)]
pub enum Message {
    List,
    Start {
        id: String,
    },
    Stop {
        kill: bool,
        id: String,
    },
    Restart {
        kill: bool,
        id: String,
    },
    Info {
        id: String,
    },
    Configure {
        id: String,
        auto_create: Option<bool>,
        auto_upgrade: Option<bool>,
        auto_delete: Option<bool>,
    },
    Reload,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum Response {
    Ok,
    Error(String),
}
