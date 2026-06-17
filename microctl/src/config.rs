use serde::Deserialize;
use std::{fs, io, path::Path};

#[derive(Debug, Deserialize)]
pub struct Config {
    pub nodes: Vec<NodeConfig>,
}

#[derive(Debug, Deserialize)]
pub struct NodeConfig {
    pub id: String,
    pub runner: String,
    #[serde(default)]
    pub settings: NodeSettings,
}

#[derive(Debug, Deserialize, Default)]
pub struct NodeSettings {
    #[serde(default)]
    pub auto_create: bool,
    #[serde(default)]
    pub auto_upgrade: bool,
    #[serde(default)]
    pub auto_delete: bool,
}

#[derive(Debug)]
pub enum ConfigError {
    Io(io::Error),
    Parse(toml::de::Error),
}

impl std::fmt::Display for ConfigError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ConfigError::Io(e) => write!(f, "io error: {e}"),
            ConfigError::Parse(e) => write!(f, "parse error: {e}"),
        }
    }
}

impl From<io::Error> for ConfigError {
    fn from(e: io::Error) -> Self {
        ConfigError::Io(e)
    }
}

impl From<toml::de::Error> for ConfigError {
    fn from(e: toml::de::Error) -> Self {
        ConfigError::Parse(e)
    }
}

pub fn load(path: &Path) -> Result<Config, ConfigError> {
    let raw = fs::read_to_string(path)?;
    Ok(toml::from_str(&raw)?)
}
