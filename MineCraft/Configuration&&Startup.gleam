// src/minemind/main.gleam
import gleam/io
import gleam/erlang

pub fn main() {
  io.println("Starting MineMind AI Assistant...")
  
  // Initialize connection to Minecraft server
  let assert Ok(connection) = connect_to_minecraft(
    "localhost",
    25575,
    "your_password_here"
  )
  
  // Start AI assistant processes
  let world_monitor = minemind/integration.monitor_world_updates(connection)
  let assistant = minemind/assistant.start_assistant(
    world_monitor,
    "GleamCraftMind"
  )
  
  // Start web interface for configuration (optional)
  let web_ui = minemind/web.start_server(8080)
  
  io.println("MineMind is now assisting in your Minecraft world!")
  io.println("Chat with me using: /msg GleamCraftMind <your question>")
  
  // Keep the main process alive
  erlang.process.sleep_forever()
}