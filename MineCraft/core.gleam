// src/minemind/core.gleam

// Define core types for Minecraft world state
pub type Block {
  Air
  Stone
  Grass
  Dirt
  // ... other block types
}

pub type Position {
  Position(x: Int, y: Int, z: Int)
}

pub type PlayerAction {
  BreakBlock(position: Position, tool: Tool)
  PlaceBlock(position: Position, block: Block)
  Move(direction: Direction, distance: Int)
  Chat(message: String)
}

pub type WorldState {
  WorldState(
    players: Map(String, Player),
    blocks: Map(Position, Block),
    time_of_day: Int,
    weather: Weather,
    entities: List(Entity)
  )
}