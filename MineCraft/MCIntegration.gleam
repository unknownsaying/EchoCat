// src/minemind/integration.gleam
import gleam/erlang.{process, receive}
import gleam/result

// Bridge between Gleam and Minecraft (via RCON or mod API)
pub type MinecraftConnection {
  MinecraftConnection(
    server_pid: process.Pid,
    rcon_port: Int,
    world_name: String
  )
}

pub fn send_command(
  connection: MinecraftConnection,
  command: String
) -> Result(String, String) {
  // Send command via RCON protocol
  rcon_send(connection.rcon_port, command)
}

pub fn monitor_world_updates(connection: MinecraftConnection) {
  process.spawn(fn() {
    loop fn() {
      let assert Ok(update) = receive_world_update(connection)
      process.send(assistant_pid, WorldUpdate(update))
      loop()
    }
  })
}