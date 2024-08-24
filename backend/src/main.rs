use reallystick::{configuration::get_configuration, startup::Application};

#[tokio::main]
async fn main() {
    env_logger::init();

    let configuration = get_configuration().expect("Failed to read configuration.");
    let application = Application::build(configuration.clone())
        .await
        .expect("Failed to build the app");

    println!(
        "🚀  Server started successfully at : http://{}:{}",
        configuration.application.host, configuration.application.port
    );

    if let Err(e) = application.run_until_stopped().await {
        eprintln!("Server failed: {}", e);
    }
}
