// src/gleamcraft/gameplay/controller.gleam
import gleam/io
import gleam/option.{Option, None, Some}
import gleam/erlang.{process, receive}
import gleam/list
import gleam/map
import gleam/result

// ====================
// Input System
// ====================

pub type InputEvent {
  KeyDown(key: Key, modifiers: Modifiers)
  KeyUp(key: Key, modifiers: Modifiers)
  MouseMove(x: Float, y: Float, delta_x: Float, delta_y: Float)
  MouseDown(button: MouseButton, x: Float, y: Float)
  MouseUp(button: MouseButton, x: Float, y: Float)
  MouseScroll(delta: Float)
  GamepadConnected(id: Int)
  GamepadDisconnected(id: Int)
  GamepadButton(button: GamepadButton, value: Float)
  GamepadAxis(axis: GamepadAxis, value: Float)
  TouchStart(id: Int, x: Float, y: Float)
  TouchMove(id: Int, x: Float, y: Float)
  TouchEnd(id: Int)
  WindowResize(width: Int, height: Int)
  WindowFocus(focused: Bool)
}

pub type Key {
  KeyW
  KeyA
  KeyS
  KeyD
  KeySpace
  KeyShift
  KeyCtrl
  KeyE         // Inventory
  KeyQ         // Drop item
  KeyR         // Reload/use
  KeyF         // Interact
  KeyT         // Chat
  KeyEscape
  KeyTab
  Key1 | Key2 | Key3 | Key4 | Key5 | Key6 | Key7 | Key8 | Key9 | Key0
  KeyF1 | KeyF2 | KeyF3 | KeyF4 | KeyF5
}

pub type Modifiers {
  Modifiers(
    shift: Bool,
    ctrl: Bool,
    alt: Bool,
    meta: Bool
  )
}

pub type GamepadButton {
  ButtonA | ButtonB | ButtonX | ButtonY
  ButtonLB | ButtonRB
  ButtonBack | ButtonStart
  ButtonLeftStick | ButtonRightStick
  DPadUp | DPadDown | DPadLeft | DPadRight
}

pub type GamepadAxis {
  LeftStickX | LeftStickY
  RightStickX | RightStickY
  LeftTrigger | RightTrigger
}

// ====================
// Action System
// ====================

pub type PlayerAction {
  MoveForward
  MoveBackward
  MoveLeft
  MoveRight
  Jump
  Sneak
  Sprint
  BreakBlock
  PlaceBlock
  UseItem
  DropItem
  SwapHands
  OpenInventory
  SelectHotbarSlot(slot: Int)
  TakeScreenshot
  OpenChat
  ToggleDebugInfo
  ToggleFullscreen
  ExitGame
}

pub type ControllerState {
  ControllerState(
    // Movement
    movement_vector: {x: Float, y: Float, z: Float},
    is_sprinting: Bool,
    is_sneaking: Bool,
    is_jumping: Bool,
    
    // Camera
    yaw: Float,      // Horizontal rotation (-180 to 180)
    pitch: Float,    // Vertical rotation (-90 to 90)
    camera_sensitivity: Float,
    
    // Interaction
    selected_hotbar_slot: Int,
    left_mouse_down: Bool,
    right_mouse_down: Bool,
    interaction_cooldown: Int,
    
    // Game state
    is_paused: Bool,
    is_inventory_open: Bool,
    is_chat_open: Bool,
    
    // Input buffer for combos
    input_buffer: List({action: PlayerAction, timestamp: Int}),
    last_action_time: Int
  )
}

pub type ControllerConfig {
  ControllerConfig(
    key_bindings: Map(Key, PlayerAction),
    mouse_sensitivity: Float,
    invert_y_axis: Bool,
    fov: Float,
    render_distance: Int,
    difficulty: Difficulty,
    game_mode: GameMode,
    view_bobbing: Bool,
    particles: Bool,
    sound_volume: Float,
    music_volume: Float
  )
}

// ====================
// Controller Process
// ====================

pub fn start_controller(
  initial_config: ControllerConfig,
  world_pid: process.Pid,
  renderer_pid: process.Pid
) -> process.Pid {
  process.spawn(fn() -> controller_loop(
    initial_config,
    ControllerState(
      movement_vector: {x: 0.0, y: 0.0, z: 0.0},
      is_sprinting: False,
      is_sneaking: False,
      is_jumping: False,
      yaw: 0.0,
      pitch: 0.0,
      camera_sensitivity: initial_config.mouse_sensitivity,
      selected_hotbar_slot: 0,
      left_mouse_down: False,
      right_mouse_down: False,
      interaction_cooldown: 0,
      is_paused: False,
      is_inventory_open: False,
      is_chat_open: False,
      input_buffer: [],
      last_action_time: 0
    ),
    world_pid,
    renderer_pid
  ))
}

fn controller_loop(
  config: ControllerConfig,
  state: ControllerState,
  world_pid: process.Pid,
  renderer_pid: process.Pid
) -> Nil {
  // Receive input events with timeout for frame updates
  case process.receive(16) {  // ~60 FPS
    Ok(event) ->
      let #(updated_state, world_commands, render_commands) =
        handle_input_event(event, state, config)
      
      // Send commands to world
      list.each(world_commands, fn(command) {
        process.send(world_pid, command)
      })
      
      // Send commands to renderer
      list.each(render_commands, fn(command) {
        process.send(renderer_pid, command)
      })
      
      // Update cooldowns
      let cooldown = if state.interaction_cooldown > 0 {
        state.interaction_cooldown - 1
      } else {
        0
      }
      
      controller_loop(
        config,
        ControllerState(..updated_state, interaction_cooldown: cooldown),
        world_pid,
        renderer_pid
      )
    
    // Timeout - update movement/physics
    Error(Nil) ->
      let #(updated_state, physics_commands) =
        update_movement(state, config)
      
      list.each(physics_commands, fn(command) {
        process.send(world_pid, command)
      })
      
      controller_loop(config, updated_state, world_pid, renderer_pid)
  }
}

fn handle_input_event(
  event: InputEvent,
  state: ControllerState,
  config: ControllerConfig
) -> #(ControllerState, List(WorldCommand), List(RenderCommand)) {
  case event {
    KeyDown(key, _) ->
      case map.get(config.key_bindings, key) {
        Some(action) ->
          let #(new_state, world_cmds, render_cmds) =
            handle_action(action, True, state, config)
          #(new_state, world_cmds, render_cmds)
        
        None -> #(state, [], [])
      }
    
    KeyUp(key, _) ->
      case map.get(config.key_bindings, key) {
        Some(action) ->
          let #(new_state, world_cmds, render_cmds) =
            handle_action(action, False, state, config)
          #(new_state, world_cmds, render_cmds)
        
        None -> #(state, [], [])
      }
    
    MouseMove(x, y, delta_x, delta_y) ->
      // Update camera rotation
      let sensitivity = if state.is_sneaking {
        config.mouse_sensitivity * 0.5
      } else if state.is_sprinting {
        config.mouse_sensitivity * 1.5
      } else {
        config.mouse_sensitivity
      }
      
      let new_yaw = state.yaw - delta_x * sensitivity
      let pitch_delta = if config.invert_y_axis {
        delta_y * sensitivity
      } else {
        -delta_y * sensitivity
      }
      let new_pitch = float.clamp(state.pitch + pitch_delta, -89.0, 89.0)
      
      let render_commands = [
        UpdateCamera(new_yaw, new_pitch, config.fov)
      ]
      
      #(
        ControllerState(..state, yaw: new_yaw, pitch: new_pitch),
        [],
        render_commands
      )
    
    MouseDown(button, x, y) ->
      case button {
        LeftButton ->
          // Start breaking block
          let render_commands = [SetCrosshairState(Breaking)]
          #(
            ControllerState(..state, left_mouse_down: True),
            [BeginBlockBreak(x, y)],
            render_commands
          )
        
        RightButton ->
          // Place block or use item
          let render_commands = [SetCrosshairState(Placing)]
          #(
            ControllerState(..state, right_mouse_down: True),
            [BeginBlockPlace(x, y)],
            render_commands
          )
        
        _ -> #(state, [], [])
      }
    
    MouseUp(button, x, y) ->
      case button {
        LeftButton ->
          // Complete block break
          let render_commands = [SetCrosshairState(Normal)]
          #(
            ControllerState(..state, left_mouse_down: False),
            [CompleteBlockBreak(x, y)],
            render_commands
          )
        
        RightButton ->
          // Complete block placement
          let render_commands = [SetCrosshairState(Normal)]
          #(
            ControllerState(..state, right_mouse_down: False),
            [CompleteBlockPlace(x, y)],
            render_commands
          )
        
        _ -> #(state, [], [])
      }
    
    MouseScroll(delta) ->
      // Change hotbar slot
      let new_slot = (state.selected_hotbar_slot - int.round(delta)) % 9
      let clamped_slot = if new_slot < 0 { 8 } else { new_slot }
      
      let render_commands = [UpdateHotbarSelection(clamped_slot)]
      
      #(
        ControllerState(..state, selected_hotbar_slot: clamped_slot),
        [SelectHotbarSlot(clamped_slot)],
        render_commands
      )
    
    WindowResize(width, height) ->
      // Update renderer with new viewport
      let render_commands = [
        ResizeViewport(width, height),
        UpdateProjectionMatrix(width, height, config.fov)
      ]
      
      #(state, [], render_commands)
    
    _ -> #(state, [], [])  // Handle other events similarly
  }
}

fn handle_action(
  action: PlayerAction,
  pressed: Bool,
  state: ControllerState,
  config: ControllerConfig
) -> #(ControllerState, List(WorldCommand), List(RenderCommand)) {
  case action {
    MoveForward ->
      let movement = if pressed {
        {x: state.movement_vector.x, y: state.movement_vector.y, z: -1.0}
      } else {
        {x: state.movement_vector.x, y: state.movement_vector.y, z: 0.0}
      }
      #(ControllerState(..state, movement_vector: movement), [], [])
    
    MoveBackward ->
      let movement = if pressed {
        {x: state.movement_vector.x, y: state.movement_vector.y, z: 1.0}
      } else {
        {x: state.movement_vector.x, y: state.movement_vector.y, z: 0.0}
      }
      #(ControllerState(..state, movement_vector: movement), [], [])
    
    MoveLeft ->
      let movement = if pressed {
        {x: -1.0, y: state.movement_vector.y, z: state.movement_vector.z}
      } else {
        {x: 0.0, y: state.movement_vector.y, z: state.movement_vector.z}
      }
      #(ControllerState(..state, movement_vector: movement), [], [])
    
    MoveRight ->
      let movement = if pressed {
        {x: 1.0, y: state.movement_vector.y, z: state.movement_vector.z}
      } else {
        {x: 0.0, y: state.movement_vector.y, z: state.movement_vector.z}
      }
      #(ControllerState(..state, movement_vector: movement), [], [])
    
    Jump ->
      if pressed && not state.is_jumping {
        let world_commands = [PlayerJump]
        #(
          ControllerState(..state, is_jumping: True),
          world_commands,
          []
        )
      } else if not pressed {
        #(ControllerState(..state, is_jumping: False), [], [])
      } else {
        #(state, [], [])
      }
    
    Sneak ->
      let new_state = ControllerState(..state, is_sneaking: pressed)
      let render_commands = if pressed {
        [UpdatePlayerState(Sneaking)]
      } else {
        [UpdatePlayerState(Standing)]
      }
      #(new_state, [], render_commands)
    
    Sprint ->
      let new_state = ControllerState(..state, is_sprinting: pressed)
      let render_commands = if pressed {
        [UpdatePlayerState(Sprinting), SetCameraFOV(110.0)]
      } else {
        [UpdatePlayerState(Walking), SetCameraFOV(config.fov)]
      }
      #(new_state, [], render_commands)
    
    BreakBlock ->
      if pressed && state.interaction_cooldown == 0 {
        let world_commands = [BreakBlockAtCrosshair]
        let new_state = ControllerState(..state, interaction_cooldown: 5)
        #(new_state, world_commands, [])
      } else {
        #(state, [], [])
      }
    
    PlaceBlock ->
      if pressed && state.interaction_cooldown == 0 {
        let world_commands = [PlaceBlockAtCrosshair]
        let new_state = ControllerState(..state, interaction_cooldown: 5)
        #(new_state, world_commands, [])
      } else {
        #(state, [], [])
      }
    
    OpenInventory ->
      if pressed {
        let new_state = ControllerState(..state, is_inventory_open: not state.is_inventory_open)
        let render_commands = if new_state.is_inventory_open {
          [OpenInventoryUI, PauseGame(True)]
        } else {
          [CloseInventoryUI, PauseGame(False)]
        }
        #(new_state, [], render_commands)
      } else {
        #(state, [], [])
      }
    
    SelectHotbarSlot(slot) ->
      if pressed {
        let render_commands = [UpdateHotbarSelection(slot)]
        #(
          ControllerState(..state, selected_hotbar_slot: slot),
          [SelectHotbarSlot(slot)],
          render_commands
        )
      } else {
        #(state, [], [])
      }
    
    OpenChat ->
      if pressed {
        let new_state = ControllerState(..state, is_chat_open: True)
        let render_commands = [OpenChatUI, PauseGame(True)]
        #(new_state, [], render_commands)
      } else {
        #(state, [], [])
      }
    
    ToggleDebugInfo ->
      if pressed {
        let render_commands = [ToggleDebugOverlay]
        #(state, [], render_commands)
      } else {
        #(state, [], [])
      }
    
    TakeScreenshot ->
      if pressed {
        let render_commands = [TakeScreenshot]
        #(state, [], render_commands)
      } else {
        #(state, [], [])
      }
    
    ToggleFullscreen ->
      if pressed {
        let render_commands = [ToggleFullscreen]
        #(state, [], render_commands)
      } else {
        #(state, [], [])
      }
    
    ExitGame ->
      if pressed {
        let render_commands = [ExitApplication]
        #(state, [], render_commands)
      } else {
        #(state, [], [])
      }
    
    _ -> #(state, [], [])
  }
}

fn update_movement(
  state: ControllerState,
  config: ControllerConfig
) -> #(ControllerState, List(PhysicsCommand)) {
  if state.is_paused || state.is_inventory_open || state.is_chat_open {
    #(state, [])
  } else {
    // Calculate movement based on yaw
    let yaw_radians = state.yaw * 0.0174533  // Convert to radians
    
    // Forward/backward movement
    let forward_x = -float.sin(yaw_radians) * state.movement_vector.z
    let forward_z = -float.cos(yaw_radians) * state.movement_vector.z
    
    // Left/right movement (strafe)
    let strafe_x = -float.cos(yaw_radians) * state.movement_vector.x
    let strafe_z = float.sin(yaw_radians) * state.movement_vector.x
    
    // Combine movements
    let move_x = forward_x + strafe_x
    let move_z = forward_z + strafe_z
    
    // Normalize diagonal movement
    let length = float.sqrt(move_x * move_x + move_z * move_z)
    let normalized_x = if length > 0.0 { move_x / length } else { 0.0 }
    let normalized_z = if length > 0.0 { move_z / length } else { 0.0 }
    
    // Apply sprint multiplier
    let speed = if state.is_sprinting { 1.3 } else if state.is_sneaking { 0.3 } else { 1.0 }
    
    let commands = [
      MovePlayer({
        x: normalized_x * speed,
        y: if state.is_jumping { 1.0 } else { 0.0 },
        z: normalized_z * speed
      })
    ]
    
    #(state, commands)
  }
}

// ====================
// Configuration Management
// ====================

pub fn load_configuration() -> Result(ControllerConfig, String) {
  // Load from file or use defaults
  case read_config_file("config.json") {
    Ok(content) -> parse_config_json(content)
    Error(_) -> Ok(default_configuration())
  }
}

fn default_configuration() -> ControllerConfig {
  let key_bindings = map.from_list([
    #(KeyW, MoveForward),
    #(KeyA, MoveLeft),
    #(KeyS, MoveBackward),
    #(KeyD, MoveRight),
    #(KeySpace, Jump),
    #(KeyShift, Sneak),
    #(KeyCtrl, Sprint),
    #(KeyE, OpenInventory),
    #(KeyQ, DropItem),
    #(KeyF, UseItem),
    #(KeyT, OpenChat),
    #(KeyEscape, ExitGame),
    #(Key1, SelectHotbarSlot(0)),
    #(Key2, SelectHotbarSlot(1)),
    #(Key3, SelectHotbarSlot(2)),
    #(Key4, SelectHotbarSlot(3)),
    #(Key5, SelectHotbarSlot(4)),
    #(Key6, SelectHotbarSlot(5)),
    #(Key7, SelectHotbarSlot(6)),
    #(Key8, SelectHotbarSlot(7)),
    #(Key9, SelectHotbarSlot(8)),
    #(KeyF3, ToggleDebugInfo),
    #(KeyF2, TakeScreenshot),
    #(KeyF11, ToggleFullscreen)
  ])
  
  ControllerConfig(
    key_bindings: key_bindings,
    mouse_sensitivity: 0.002,
    invert_y_axis: False,
    fov: 90.0,
    render_distance: 8,
    difficulty: Normal,
    game_mode: Survival,
    view_bobbing: True,
    particles: True,
    sound_volume: 1.0,
    music_volume: 0.5
  )
}

pub fn save_configuration(config: ControllerConfig) -> Result(Nil, String) {
  let json = config_to_json(config)
  write_config_file("config.json", json)
}

// ====================
// Input Buffer System for Combos
// ====================

pub type Combo {
  DoubleJump
  Dash
  PowerMine
  QuickPlace
  BlockShield
}

pub fn check_combo(buffer: List({action: PlayerAction, timestamp: Int})) -> Option(Combo) {
  case buffer {
    // Double jump: Jump within 300ms of previous jump
    [{action: Jump, time: t1}, {action: Jump, time: t2}, ..] 
      if t2 - t1 < 300 -> Some(DoubleJump)
    
    // Dash: Sprint + forward + forward quickly
    [
      {action: Sprint, time: t1},
      {action: MoveForward, time: t2},
      {action: MoveForward, time: t3},
      ..
    ] if t3 - t1 < 500 -> Some(Dash)
    
    // Power mine: Sneak + break block
    [
      {action: Sneak, time: t1},
      {action: BreakBlock, time: t2},
      ..
    ] if t2 - t1 < 300 -> Some(PowerMine)
    
    _ -> None
  }
}