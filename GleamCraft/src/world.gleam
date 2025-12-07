// src/gleamcraft/world/voxel.gleam
pub type BlockId {
  Air
  Stone
  Grass
  Dirt
  Wood
  Leaves
  Water
  Sand
  Glass
  // ... other blocks
}

pub type Block {
  Block(
    id: BlockId,
    position: Position,
    texture_coords: TextureCoords,
    light_level: Int,
    is_transparent: Bool,
    is_solid: Bool
  )
}

pub type Chunk {
  Chunk(
    position: ChunkPosition,
    blocks: Array(3, 3, 3, Option(Block)), // 16x256x16 optimized
    is_dirty: Bool,
    mesh: Option(Mesh)
  )
}

pub type World {
  World(
    seed: Int,
    chunks: Map(ChunkPosition, Chunk),
    world_time: Float,
    dimension: Dimension
  )
}

pub fn generate_chunk(position: ChunkPosition, seed: Int) -> Chunk {
  use x <- list.range(0, 15)
  use y <- list.range(0, 255)
  use z <- list.range(0, 15)
  
  let height = perlin_noise_3d(x + position.x * 16, z + position.z * 16, seed)
  
  let block = case y {
    y if y < height - 3 -> Some(Stone)
    y if y < height -> Some(Dirt)
    y if y == height -> Some(Grass)
    _ -> None
  }
  
  // Convert to array format
  array.from_list(block)
}