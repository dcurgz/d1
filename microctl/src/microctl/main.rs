use clap::{Parser, Subcommand};
use microctl::protocol::{DAEMON_ADDR, Message, Response};
use std::io::{BufRead, BufReader, Write};
use std::net::TcpStream;

#[derive(Parser)]
#[command(name = "microctl", about = "MicroVM management CLI")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// List all MicroVM nodes.
    #[command(alias = "ls", alias = "l")]
    List,
    /// Start a MicroVM node.
    Start { id: String },
    /// Stop a MicroVM node.
    Stop {
        #[arg(short = 'k', long)]
        kill: bool,
        id: String,
    },
    /// Restart a MicroVM node.
    Restart {
        #[arg(short = 'k', long)]
        kill: bool,
        id: String,
    },
    /// Get information about a MicroVM node.
    Info { id: String },
    /// Override declarative node configuration.
    Configure {
        id: String,
        /// When a new node is added to the configuration, start it automatically. Default: y
        #[arg(long, value_parser = parse_yn, value_name = "y|n")]
        auto_run: Option<bool>,
        /// When a node has its runner derivation replaced, restart it automatically. Default: y
        #[arg(long, value_parser = parse_yn, value_name = "y|n")]
        auto_upgrade: Option<bool>,
        /// When a node is removed from the configuration, stop it automatically. Default: y
        #[arg(long, value_parser = parse_yn, value_name = "y|n")]
        auto_delete: Option<bool>,
    },
    /// Tell the daemon to reload its node configuration.
    Reload,
}

fn parse_yn(s: &str) -> Result<bool, String> {
    match s {
        "y" | "Y" => Ok(true),
        "n" | "N" => Ok(false),
        _ => Err(format!("expected 'y' or 'n', got '{s}'")),
    }
}

fn main() {
    let cli = Cli::parse();

    let msg = match cli.command {
        Command::List => Message::List,
        Command::Start { id } => Message::Start { id },
        Command::Stop { kill, id } => Message::Stop { kill, id },
        Command::Restart { kill, id } => Message::Restart { kill, id },
        Command::Info { id } => Message::Info { id },
        Command::Configure { id, auto_run, auto_upgrade, auto_delete } => {
            Message::Configure { id, auto_run, auto_upgrade, auto_delete }
        }
        Command::Reload => Message::Reload,
    };

    let response = send(msg).unwrap_or_else(|e| {
        eprintln!("error: {e}");
        std::process::exit(1);
    });

    match response {
        Response::Ok => {}
        Response::Error(msg) => {
            eprintln!("daemon error: {msg}");
            std::process::exit(1);
        }
    }
}

fn send(msg: Message) -> Result<Response, String> {
    let mut stream =
        TcpStream::connect(DAEMON_ADDR).map_err(|e| format!("failed to connect: {e}"))?;

    let mut line = serde_json::to_string(&msg).map_err(|e| e.to_string())?;
    line.push('\n');
    stream
        .write_all(line.as_bytes())
        .map_err(|e| format!("failed to send: {e}"))?;

    let mut response_line = String::new();
    BufReader::new(&stream)
        .read_line(&mut response_line)
        .map_err(|e| format!("failed to read response: {e}"))?;

    serde_json::from_str(&response_line).map_err(|e| format!("invalid response: {e}"))
}
