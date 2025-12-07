// src/gleamcraft/graphics/display.gleam
import gleam/io
import gleam/option.{Option, None, Some}
import gleam/erlang.{process, receive}
import gleam/list
import gleam/map
import gleam/array
import gleam/int

// ====================
// Graphics System Types
// ====================

pub type RenderCommand {
  // Scene management
  ClearScene
  SetClearColor(r: Float, g: Float, b: Float, a: Float)
  
  // Camera
  UpdateCamera(position: Vector3, rotation: {yaw: Float, pitch: Float})
  SetCameraFOV(fov: Float)
  UpdateProjectionMatrix(width: Int, height: Int, fov: Float)
  
  // World rendering
  LoadChunk(position: ChunkPosition, blocks: ChunkData)
  UnloadChunk(position: ChunkPosition)
  UpdateChunk(position: ChunkPosition, changes: List(BlockUpdate))
  SetBlock(position: Position, block: Block)
  SetSkyColor(day_time: Float)
  SetFog(distance: Float, color: {r: Float, g: Float, b: Float})
  
  // Entities
  SpawnEntity(entity_id: Int, entity_type: EntityType, position: Vector3)
  UpdateEntity(entity_id: Int, position: Vector3, rotation: Vector3)
  RemoveEntity(entity_id: Int)
  AnimateEntity(entity_id: Int, animation: Animation, speed: Float)
  
  // Particles
  SpawnParticles(
    position: Vector3,
    particle_type: ParticleType,
    count: Int,
    velocity: Vector3,
    lifetime: Float
  )
  
  // UI
  UpdateHotbar(slots: List(ItemStack))
  UpdateHealth(health: Float, max_health: Float)
  UpdateHunger(hunger: Float)
  UpdateExperience(level: Int, progress: Float)
  ShowMessage(text: String, duration: Float)
  ShowTitle(title: String, subtitle: String, fade_in: Float, stay: Float, fade_out: Float)
  
  // Inventory UI
  OpenInventoryUI(items: List(InventorySlot), crafting_grid: List(ItemStack))
  CloseInventoryUI
  UpdateInventorySlot(slot: Int, item: Option(ItemStack))
  
  // Effects
  AddPostProcessingEffect(effect: PostProcessingEffect)
  RemovePostProcessingEffect(effect: PostProcessingEffect)
  SetAmbientOcclusion(enabled: Bool, strength: Float)
  SetAntiAliasing(enabled: Bool, samples: Int)
  
  // Debug
  ToggleWireframe
  ToggleBoundingBoxes
  ToggleChunkBorders
  SetDebugInfo(info: DebugInfo)
  
  // System
  TakeScreenshot
  ToggleFullscreen
  ResizeViewport(width: Int, height: Int)
  SetVSync(enabled: Bool)
  SetMaxFPS(fps: Int)
  
  // Performance
  SetRenderDistance(distance: Int)
  SetGraphicsQuality(quality: GraphicsQuality)
  
  ExitApplication
}

pub type GraphicsQuality {
  Low
  Medium
  High
  Ultra
}

pub type PostProcessingEffect {
  Bloom(threshold: Float, intensity: Float, radius: Float)
  MotionBlur(strength: Float)
  DepthOfField(focus_distance: Float, aperture: Float)
  ColorGrading(lut: String, intensity: Float)
  Vignette(intensity: Float, smoothness: Float, roundness: Float)
  ChromaticAberration(strength: Float)
}

pub type ParticleType {
  BlockBreak(block: BlockId)
  WaterSplash
  LavaPop
  Portal
  Firework
  Smoke
  Heart
  DamageIndicator
}

pub type Animation {
  Walk
  Run
  Jump
  Attack
  Hurt
  Idle
  Swim
}

// ====================
// Display System Process
// ====================

pub fn start_display(
  config: GraphicsConfig,
  window_title: String,
  initial_width: Int,
  initial_height: Int
) -> process.Pid {
  process.spawn(fn() -> display_loop(
    config,
    DisplayState(
      window: None,
      renderer: None,
      camera: create_camera(initial_width, initial_height, config.fov),
      loaded_chunks: map.new(),
      entities: map.new(),
      particles: [],
      ui_elements: [],
      post_processing: [],
      frame_count: 0,
      fps: 0,
      last_fps_time: 0,
      is_fullscreen: False,
      wireframe_mode: False,
      show_debug: False,
      vsync_enabled: config.vsync
    ),
    [],
    0
  ))
}

fn display_loop(
  config: GraphicsConfig,
  state: DisplayState,
  command_queue: List(RenderCommand),
  last_frame_time: Int
) -> Nil {
  // Process all queued commands
  let #(updated_state, remaining_commands) = 
    process_command_queue(command_queue, state, config)
  
  // Check for new commands
  case process.receive(0) {
    Ok(command) ->
      let new_queue = list.append(remaining_commands, [command])
      display_loop(config, updated_state, new_queue, last_frame_time)
    
    Error(Nil) ->
      // Render frame if enough time has passed
      let current_time = erlang.system_time(millisecond)
      let frame_time = 1000 // config.target_fps
      
      if current_time - last_frame_time >= frame_time {
        render_frame(updated_state, config)
        
        // Calculate FPS
        let fps_state = update_fps_counter(updated_state, current_time)
        
        display_loop(
          config,
          fps_state,
          remaining_commands,
          current_time
        )
      } else {
        // Wait a bit before checking again
        erlang.process.sleep(1)
        display_loop(config, updated_state, remaining_commands, last_frame_time)
      }
  }
}

fn process_command_queue(
  queue: List(RenderCommand),
  state: DisplayState,
  config: GraphicsConfig
) -> #(DisplayState, List(RenderCommand)) {
  fn loop(commands, current_state) {
    case commands {
      [] -> #(current_state, [])
      [command, ..rest] ->
        let new_state = execute_command(command, current_state, config)
        loop(rest, new_state)
    }
  }
  
  loop(queue, state)
}

fn execute_command(
  command: RenderCommand,
  state: DisplayState,
  config: GraphicsConfig
) -> DisplayState {
  case command {
    ClearScene ->
      clear_screen(state.renderer)
      state
    
    SetClearColor(r, g, b, a) ->
      set_clear_color(state.renderer, r, g, b, a)
      state
    
    UpdateCamera(position, rotation) ->
      update_camera(state.camera, position, rotation)
      state
    
    LoadChunk(position, blocks) ->
      let chunk_mesh = generate_chunk_mesh(blocks, position, config.texture_atlas)
      let new_chunks = map.insert(state.loaded_chunks, position, chunk_mesh)
      add_to_scene(state.renderer, chunk_mesh)
      DisplayState(..state, loaded_chunks: new_chunks)
    
    UnloadChunk(position) ->
      case map.get(state.loaded_chunks, position) {
        Some(mesh) ->
          remove_from_scene(state.renderer, mesh)
          let new_chunks = map.delete(state.loaded_chunks, position)
          DisplayState(..state, loaded_chunks: new_chunks)
        
        None -> state
      }
    
    UpdateChunk(position, changes) ->
      case map.get(state.loaded_chunks, position) {
        Some(mesh) ->
          let updated_mesh = update_chunk_mesh(mesh, changes, config.texture_atlas)
          update_mesh_in_scene(state.renderer, mesh, updated_mesh)
          let new_chunks = map.insert(state.loaded_chunks, position, updated_mesh)
          DisplayState(..state, loaded_chunks: new_chunks)
        
        None -> state
      }
    
    SpawnEntity(entity_id, entity_type, position) ->
      let entity_mesh = create_entity_mesh(entity_type, config.models)
      add_to_scene(state.renderer, entity_mesh)
      let new_entities = map.insert(state.entities, entity_id, entity_mesh)
      DisplayState(..state, entities: new_entities)
    
    UpdateEntity(entity_id, position, rotation) ->
      case map.get(state.entities, entity_id) {
        Some(mesh) ->
          update_mesh_transform(mesh, position, rotation)
          state
        
        None -> state
      }
    
    SpawnParticles(pos, particle_type, count, velocity, lifetime) ->
      let particles = create_particles(pos, particle_type, count, velocity, lifetime, config.particle_textures)
      let all_particles = list.append(state.particles, particles)
      list.each(particles, fn(particle) {
        add_to_scene(state.renderer, particle)
      })
      DisplayState(..state, particles: all_particles)
    
    UpdateHotbar(slots) ->
      update_hotbar_ui(state.ui_renderer, slots)
      state
    
    UpdateHealth(health, max_health) ->
      update_health_ui(state.ui_renderer, health, max_health)
      state
    
    ToggleWireframe ->
      let new_mode = not state.wireframe_mode
      set_wireframe_mode(state.renderer, new_mode)
      DisplayState(..state, wireframe_mode: new_mode)
    
    ToggleDebugInfo ->
      let new_mode = not state.show_debug
      DisplayState(..state, show_debug: new_mode)
    
    SetDebugInfo(info) ->
      if state.show_debug {
        render_debug_overlay(state.ui_renderer, info)
      }
      state
    
    ResizeViewport(width, height) ->
      resize_viewport(state.renderer, width, height)
      update_camera_projection(state.camera, width, height)
      state
    
    ToggleFullscreen ->
      let new_mode = not state.is_fullscreen
      set_fullscreen(state.window, new_mode)
      DisplayState(..state, is_fullscreen: new_mode)
    
    SetVSync(enabled) ->
      set_vsync(state.window, enabled)
      DisplayState(..state, vsync_enabled: enabled)
    
    TakeScreenshot ->
      take_screenshot(state.renderer, "screenshot_" <> int.to_string(state.frame_count) <> ".png")
      state
    
    AddPostProcessingEffect(effect) ->
      add_post_processing_effect(state.renderer, effect)
      let new_effects = list.append(state.post_processing, [effect])
      DisplayState(..state, post_processing: new_effects)
    
    ExitApplication ->
      cleanup(state)
      erlang.process.exit()
      state
    
    _ -> state  // Handle other commands similarly
  }
}

fn render_frame(state: DisplayState, config: GraphicsConfig) -> Nil {
  // Update particles
  let updated_particles = list.filter(state.particles, fn(particle) {
    update_particle(particle)
  })
  
  // Update animations
  map.each(state.entities, fn(_, entity) {
    update_entity_animation(entity)
  })
  
  // Clear screen
  clear_screen(state.renderer)
  
  // Set camera
  set_camera(state.renderer, state.camera)
  
  // Render world
  map.each(state.loaded_chunks, fn(_, chunk) {
    render_mesh(state.renderer, chunk)
  })
  
  // Render entities
  map.each(state.entities, fn(_, entity) {
    render_mesh(state.renderer, entity)
  })
  
  // Render particles
  list.each(updated_particles, fn(particle) {
    render_particle(state.renderer, particle)
  })
  
  // Apply post-processing
  list.each(state.post_processing, fn(effect) {
    apply_post_processing(state.renderer, effect)
  })
  
  // Render UI
  render_ui(state.ui_renderer)
  
  if state.show_debug {
    render_debug_info(state, config)
  }
  
  // Swap buffers
  swap_buffers(state.window)
}

// ====================
// Chunk Mesh Generation
// ====================

fn generate_chunk_mesh(
  blocks: ChunkData,
  position: ChunkPosition,
  texture_atlas: TextureAtlas
) -> Mesh {
  use x <- list.range(0, 15)
  use y <- list.range(0, 255)
  use z <- list.range(0, 15)
  
  let world_x = position.x * 16 + x
  let world_y = y
  let world_z = position.z * 16 + z
  
  case get_block(blocks, x, y, z) {
    Some(block) if block != Air ->
      generate_block_mesh(block, {x: world_x, y: world_y, z: world_z}, texture_atlas)
    
    _ -> EmptyMesh
  }
  |> combine_meshes
}

fn generate_block_mesh(
  block: Block,
  position: Position,
  texture_atlas: TextureAtlas
) -> Mesh {
  let vertices = []
  let indices = []
  let normals = []
  let tex_coords = []
  
  // Generate each face if neighbor is transparent
  let faces = [
    #({x: 0, y: 0, z: -1}, FaceFront),   // Front
    #({x: 0, y: 0, z: 1}, FaceBack),     // Back
    #({x: -1, y: 0, z: 0}, FaceLeft),    // Left
    #({x: 1, y: 0, z: 0}, FaceRight),    // Right
    #({x: 0, y: 1, z: 0}, FaceTop),      // Top
    #({x: 0, y: -1, z: 0}, FaceBottom)   // Bottom
  ]
  
  list.fold(faces, {vertices, indices, normals, tex_coords}, fn({normal, face}, acc) {
    // Check if neighbor block exists and is transparent
    let neighbor_pos = {
      x: position.x + normal.x,
      y: position.y + normal.y,
      z: position.z + normal.z
    }
    
    // Assume we have access to world data
    case get_block_at(neighbor_pos) {
      Some(neighbor) if neighbor.is_transparent || neighbor == Air ->
        let face_vertices = create_face_vertices(position, face, normal)
        let face_indices = create_face_indices(acc.vertices, face)
        let face_tex_coords = get_texture_coords(block, face, texture_atlas)
        
        {
          vertices: list.append(acc.vertices, face_vertices),
          indices: list.append(acc.indices, face_indices),
          normals: list.append(acc.normals, list.repeat(normal, 4)),
          tex_coords: list.append(acc.tex_coords, face_tex_coords)
        }
      
      _ -> acc
    }
  })
  |> create_mesh_from_data
}

// ====================
// UI Rendering System
// ====================

pub type UIRenderer {
  UIRenderer(
    font: Font,
    textures: Map(String, Texture),
    elements: List(UIElement),
    screen_width: Int,
    screen_height: Int
  )
}

pub type UIElement {
  Hotbar(
    position: {x: Int, y: Int},
    slots: List(ItemStack),
    selected_slot: Int
  )
  HealthBar(
    position: {x: Int, y: Int},
    health: Float,
    max_health: Float,
    is_hurting: Bool
  )
  HungerBar(
    position: {x: Int, y: Int},
    hunger: Float
  )
  ExperienceBar(
    position: {x: Int, y: Int},
    level: Int,
    progress: Float
  )
  Crosshair(
    position: {x: Int, y: Int},
    style: CrosshairStyle,
    breaking_progress: Option(Float)
  )
  ChatWindow(
    position: {x: Int, y: Int},
    messages: List(Message),
    is_open: Bool,
    input_text: String
  )
  InventoryWindow(
    position: {x: Int, y: Int},
    slots: List(InventorySlot),
    crafting_result: Option(ItemStack)
  )
  DebugOverlay(
    position: {x: Int, y: Int},
    info: DebugInfo
  )
}

fn render_ui(ui_renderer: UIRenderer) -> Nil {
  list.each(ui_renderer.elements, fn(element) {
    case element {
      Hotbar(position, slots, selected_slot) ->
        render_hotbar(ui_renderer, position, slots, selected_slot)
      
      HealthBar(position, health, max_health, is_hurting) ->
        render_health_bar(ui_renderer, position, health, max_health, is_hurting)
      
      Crosshair(position, style, breaking_progress) ->
        render_crosshair(ui_renderer, position, style, breaking_progress)
      
      DebugOverlay(position, info) ->
        render_debug_overlay(ui_renderer, position, info)
      
      _ -> Nil  // Render other elements
    }
  })
}

fn render_hotbar(
  ui_renderer: UIRenderer,
  position: {x: Int, y: Int},
  slots: List(ItemStack),
  selected_slot: Int
) -> Nil {
  let slot_width = 40
  let slot_height = 40
  let spacing = 5
  let total_width = 9 * slot_width + 8 * spacing
  
  let start_x = (ui_renderer.screen_width - total_width) / 2
  let y = 20  // 20 pixels from bottom
  
  // Draw background
  draw_rect(
    ui_renderer,
    {x: start_x - 10, y: y - 10},
    total_width + 20,
    slot_height + 20,
    {r: 0.0, g: 0.0, b: 0.0, a: 0.5}
  )
  
  // Draw slots
  list.index_map(slots, fn(slot, index) {
    let x = start_x + index * (slot_width + spacing)
    
    // Draw slot background
    if index == selected_slot {
      draw_rect(
        ui_renderer,
        {x: x - 2, y: y - 2},
        slot_width + 4,
        slot_height + 4,
        {r: 1.0, g: 1.0, b: 1.0, a: 0.8}
      )
    }
    
    draw_rect(
      ui_renderer,
      {x: x, y: y},
      slot_width,
      slot_height,
      {r: 0.2, g: 0.2, b: 0.2, a: 0.7}
    )
    
    // Draw item
    case slot {
      Some(item_stack) ->
        draw_texture(
          ui_renderer,
          get_item_texture(item_stack.item),
          {x: x + 4, y: y + 4},
          slot_width - 8,
          slot_height - 8
        )
        
        // Draw count if > 1
        if item_stack.count > 1 {
          draw_text(
            ui_renderer,
            int.to_string(item_stack.count),
            {x: x + slot_width - 20, y: y + slot_height - 20},
            16,
            {r: 1.0, g: 1.0, b: 1.0, a: 1.0}
          )
        }
      
      None -> Nil
    }
  })
}

fn render_debug_overlay(
  ui_renderer: UIRenderer,
  position: {x: Int, y: Int},
  info: DebugInfo
) -> Nil {
  let lines = [
    "FPS: " <> int.to_string(info.fps),
    "Position: " <> vector_to_string(info.player_position),
    "Chunks: " <> int.to_string(info.loaded_chunks),
    "Entities: " <> int.to_string(info.entity_count),
    "Memory: " <> int.to_string(info.memory_usage) <> "MB",
    "VSync: " <> bool.to_string(info.vsync_enabled),
    "Render Distance: " <> int.to_string(info.render_distance),
    "Time: " <> format_time(info.world_time),
    "Biome: " <> info.biome
  ]
  
  list.index_map(lines, fn(line, index) {
    draw_text(
      ui_renderer,
      line,
      {x: position.x, y: position.y + index * 20},
      16,
      {r: 1.0, g: 1.0, b: 1.0, a: 0.8}
    )
  })
}

// ====================
// Performance & Optimization
// ====================

pub type GraphicsConfig {
  GraphicsConfig(
    target_fps: Int,
    vsync: Bool,
    render_distance: Int,
    fov: Float,
    texture_pack: String,
    mipmap_level: Int,
    anisotropic_filtering: Int,
    shadow_quality: ShadowQuality,
    water_reflections: Bool,
    clouds: Bool,
    smooth_lighting: Bool,
    fancy_graphics: Bool,
    fancy_leaves: Bool,
    entity_shadows: Bool
  )
}

fn optimize_chunk_rendering(
  chunks: Map(ChunkPosition, Mesh),
  camera_position: Vector3,
  render_distance: Int
) -> List(Mesh> {
  // Frustum culling
  let frustum = calculate_view_frustum(camera_position)
  
  map.fold(chunks, [], fn(position, mesh, visible_chunks) {
    if is_chunk_in_frustum(position, frustum) &&
       distance_to_chunk(position, camera_position) <= render_distance * 16 {
      list.append(visible_chunks, mesh)
    } else {
      visible_chunks
    }
  })
}

fn level_of_detail(
  mesh: Mesh,
  distance: Float
) -> Mesh {
  // Simplify mesh based on distance
  case distance {
    d if d > 256.0 -> simplify_mesh(mesh, 0.25)  // 75% reduction
    d if d > 128.0 -> simplify_mesh(mesh, 0.5)   // 50% reduction
    d if d > 64.0 -> simplify_mesh(mesh, 0.75)   // 25% reduction
    _ -> mesh
  }
}

// ====================
// Shader System
// ====================

pub type ShaderProgram {
  ShaderProgram(
    vertex_shader: String,
    fragment_shader: String,
    uniforms: Map(String, UniformValue),
    attributes: Map(String, Int)
  )
}

pub type UniformValue {
  FloatValue(value: Float)
  IntValue(value: Int)
  Vec2Value(x: Float, y: Float)
  Vec3Value(x: Float, y: Float, z: Float)
  Vec4Value(x: Float, y: Float, z: Float, w: Float)
  Mat4Value(matrix: Matrix4)
  TextureValue(texture_unit: Int)
}

fn create_block_shader() -> ShaderProgram {
  let vertex_shader = "
    attribute vec3 a_position;
    attribute vec3 a_normal;
    attribute vec2 a_texCoord;
    
    uniform mat4 u_model;
    uniform mat4 u_view;
    uniform mat4 u_projection;
    uniform vec3 u_lightDirection;
    uniform vec3 u_cameraPosition;
    
    varying vec2 v_texCoord;
    varying float v_lighting;
    varying float v_fogDepth;
    
    void main() {
      vec4 worldPosition = u_model * vec4(a_position, 1.0);
      vec4 viewPosition = u_view * worldPosition;
      gl_Position = u_projection * viewPosition;
      
      v_texCoord = a_texCoord;
      
      // Simple lighting
      float directional = max(dot(a_normal, u_lightDirection), 0.0);
      float ambient = 0.4;
      v_lighting = clamp(directional + ambient, 0.0, 1.0);
      
      // Fog calculation
      v_fogDepth = length(viewPosition.xyz);
    }
  "
  
  let fragment_shader = "
    precision mediump float;
    
    uniform sampler2D u_texture;
    uniform vec4 u_fogColor;
    uniform float u_fogDensity;
    uniform float u_dayTime;
    
    varying vec2 v_texCoord;
    varying float v_lighting;
    varying float v_fogDepth;
    
    void main() {
      vec4 texColor = texture2D(u_texture, v_texCoord);
      
      if (texColor.a < 0.1) {
        discard;
      }
      
      // Apply lighting
      vec4 litColor = texColor * vec4(v_lighting, v_lighting, v_lighting, 1.0);
      
      // Apply time-based tint (night/dusk/dawn)
      float timeFactor = sin(u_dayTime) * 0.5 + 0.5;
      vec4 timeTint = mix(
        vec4(0.6, 0.7, 1.0, 1.0),  // Night
        vec4(1.0, 0.9, 0.7, 1.0),  // Day
        timeFactor
      );
      vec4 timeAdjusted = litColor * timeTint;
      
      // Apply fog
      float fogAmount = 1.0 - exp(-u_fogDensity * v_fogDepth * v_fogDepth);
      vec4 finalColor = mix(timeAdjusted, u_fogColor, fogAmount);
      
      gl_FragColor = finalColor;
    }
  "
  
  ShaderProgram(
    vertex_shader: vertex_shader,
    fragment_shader: fragment_shader,
    uniforms: map.from_list([
      #("u_model", Mat4Value(identity_matrix())),
      #("u_view", Mat4Value(identity_matrix())),
      #("u_projection", Mat4Value(identity_matrix())),
      #("u_lightDirection", Vec3Value(0.0, -1.0, 0.0)),
      #("u_cameraPosition", Vec3Value(0.0, 0.0, 0.0)),
      #("u_fogColor", Vec4Value(0.8, 0.9, 1.0, 1.0)),
      #("u_fogDensity", FloatValue(0.001)),
      #("u_dayTime", FloatValue(0.0))
    ]),
    attributes: map.from_list([
      #("a_position", 0),
      #("a_normal", 1),
      #("a_texCoord", 2)
    ])
  )
}

// ====================
// Main Display Setup
// ====================

pub fn initialize_graphics(
  window_title: String,
  width: Int,
  height: Int,
  config: GraphicsConfig
) -> Result(process.Pid, String) {
  // Initialize window and OpenGL context
  case create_window(window_title, width, height) {
    Ok(window) ->
      case create_renderer(window, config) {
        Ok(renderer) ->
          let display_pid = start_display(config, window_title, width, height)
          Ok(display_pid)
        
        Error(msg) -> Error("Failed to create renderer: " <> msg)
      }
    
    Error(msg) -> Error("Failed to create window: " <> msg)
  }
}

// External functions for platform-specific graphics
external fn create_window(title: String, width: Int, height: Int) -> Result(Window, String) =
  "../native/graphics.js" "createWindow"

external fn create_renderer(window: Window, config: GraphicsConfig) -> Result(Renderer, String) =
  "../native/graphics.js" "createRenderer"

external fn swap_buffers(window: Window) -> Nil =
  "../native/graphics.js" "swapBuffers"

external fn set_vsync(window: Window, enabled: Bool) -> Nil =
  "../native/graphics.js" "setVSync"

external fn set_fullscreen(window: Window, enabled: Bool) -> Nil =
  "../native/graphics.js" "setFullscreen"