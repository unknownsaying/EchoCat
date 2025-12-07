// Example of how to integrate controller and display
import gleamcraft/gameplay/controller
import gleamcraft/graphics/display

pub fn start_game() -> Nil {
  // Load configurations
  let config = controller.load_configuration()
    |> result.unwrap(controller.default_configuration())
  
  // Initialize graphics
  let display_pid = display.initialize_graphics(
    "GleamCraft RL",
    1280,
    720,
    display.default_graphics_config()
  )
  |> result.unwrap
  
  // Initialize game world
  let world_pid = world.start_world(42)
  
  // Start controller
  let controller_pid = controller.start_controller(
    config,
    world_pid,
    display_pid
  )
  
  // Send initial render commands
  display.send(display_pid, display.SetClearColor(0.53, 0.81, 0.92, 1.0))
  display.send(display_pid, display.SetRenderDistance(config.render_distance))
  
  // Game loop
  loop_forever()
}

fn loop_forever() -> Nil {
  erlang.process.sleep(1000)
  loop_forever()
}