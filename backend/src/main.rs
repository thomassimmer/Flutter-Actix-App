use std::net::TcpListener;

use reallystick::{configuration::get_configuration, startup::run};

#[tokio::main]
async fn main() {
    let configuration = get_configuration().expect("Failed to read configuration.");

    let address = format!(
        "{}:{}",
        configuration.application.host, configuration.application.port
    );
    let listener = TcpListener::bind(address).unwrap();

    let _ = run(listener, configuration).unwrap();
}
