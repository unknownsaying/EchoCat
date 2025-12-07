// src/graphics/webgl_port.gleam
// Port to JavaScript for WebGL rendering
import gleam/erlang/process

pub type RenderCommand {
  CreateChunkMesh(position: ChunkPosition, vertices: List(Float))
  UpdateEntityPosition(entity_id: Int, position: Vector3)
  SetBlock(position: Position, block: Block)
  SetSkyColor(color: {Float, Float, Float, Float})
}

pub type GraphicsSystem {
  GraphicsSystem(
    port: process.Pid,
    shaders: Map(ShaderType, ShaderProgram),
    textures: TextureAtlas,
    camera: Camera
  )
}

// Port to JavaScript
external fn start_graphics_system() -> process.Pid =
  "../javascript/webgl.js" "startGraphicsSystem"

external fn send_render_command(pid: process.Pid, command: RenderCommand) -> Nil =
  "../javascript/webgl.js" "sendRenderCommand"

// JavaScript side (webgl.js)
// Uses Three.js or raw WebGL for rendering