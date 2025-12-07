// src/minemind/assistant.gleam
import minemind/core.{WorldState, PlayerAction}
import gleam/erlang.{process, receive}
import gleam/list

// The AI Assistant process
pub fn start_assistant(world_pid: process.Pid, player_name: String) {
  process.start(fn() -> assistant_loop(world_pid, player_name, initial_memory()))
}

fn assistant_loop(
  world_pid: process.Pid,
  player_name: String,
  memory: AssistantMemory
) -> Nil {
  // Receive events from the Minecraft world
  let assert Ok(event) = process.receive(100)
  
  case event {
    PlayerChat(sender, message) ->
      // Process chat commands
      case parse_command(message) {
        Ok(command) ->
          execute_command(command, world_pid, memory)
        Error(_) ->
          // Use AI to generate helpful response
          respond_naturally(message, world_pid, memory)
      }
    
    WorldUpdate(new_state) ->
      // Update internal world model
      let updated_memory = update_memory(memory, new_state)
      assistant_loop(world_pid, player_name, updated_memory)
    
    ResourceRequest(player, resource) ->
      // AI-driven resource gathering assistance
      let path = find_nearest_resource(resource, memory.world_state)
      suggest_path(player, path, world_pid)
    
    DangerAlert(danger_type, position) ->
      // Proactive safety warnings
      warn_player(player_name, danger_type, position, world_pid)
  }
  
  assistant_loop(world_pid, player_name, memory)
}