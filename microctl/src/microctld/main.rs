use clap::Parser;
use microctl::config::{self, Config};
use microctl::protocol::{Message, Response};
use std::path::PathBuf;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpListener;
use tokio::sync::RwLock;

use microctl::protocol::DAEMON_ADDR;

#[derive(Parser)]
struct Args {
    #[arg(long)]
    config: PathBuf,
}

#[tokio::main]
async fn main() {
    let args = Args::parse();
    let cfg = config::load(&args.config).unwrap_or_else(|e| {
        eprintln!("failed to load config: {e}");
        std::process::exit(1);
    });
    let config_path = Arc::new(args.config);
    let state = Arc::new(RwLock::new(cfg));

    let listener = TcpListener::bind(DAEMON_ADDR).await.expect("failed to bind");
    eprintln!("microctld listening on {DAEMON_ADDR}");

    loop {
        let (stream, _addr) = listener.accept().await.expect("accept failed");
        tokio::spawn(handle_connection(
            stream,
            Arc::clone(&config_path),
            Arc::clone(&state),
        ));
    }
}

async fn handle_connection(
    stream: tokio::net::TcpStream,
    config_path: Arc<PathBuf>,
    state: Arc<RwLock<Config>>,
) {
    let (reader, mut writer) = stream.into_split();
    let mut lines = BufReader::new(reader).lines();

    while let Ok(Some(line)) = lines.next_line().await {
        let response = match serde_json::from_str::<Message>(&line) {
            Ok(msg) => handle_message(msg, &config_path, &state).await,
            Err(e) => Response::Error(format!("invalid message: {e}")),
        };
        let mut json = serde_json::to_string(&response).unwrap();
        json.push('\n');
        if writer.write_all(json.as_bytes()).await.is_err() {
            break;
        }
    }
}

async fn handle_message(
    msg: Message,
    config_path: &PathBuf,
    state: &RwLock<Config>,
) -> Response {
    eprintln!("received: {msg:?}");
    match msg {
        Message::Reload => match config::load(config_path) {
            Ok(cfg) => {
                *state.write().await = cfg;
                eprintln!("config reloaded from {}", config_path.display());
                Response::Ok
            }
            Err(e) => Response::Error(format!("reload failed: {e}")),
        },
        _ => Response::Ok,
    }
}
