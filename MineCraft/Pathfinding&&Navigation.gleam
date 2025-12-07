// src/minemind/navigation.gleam
import gleam/list
import gleam/map
import gleam/result

pub fn find_optimal_path(
  start: Position,
  goal: Position,
  world_state: WorldState
) -> Result(List(Position), String) {
  // A* algorithm implementation for Minecraft terrain
  use open_set <- priority_queue.new()
  use came_from <- map.new()
  use g_score <- map.new()
  use f_score <- map.new()
  
  // Initialize with start position
  priority_queue.insert(open_set, start, heuristic(start, goal))
  map.insert(g_score, start, 0.0)
  map.insert(f_score, start, heuristic(start, goal))
  
  // Search loop
  fn search(current) {
    if current == goal {
      reconstruct_path(came_from, current)
    } else {
      for neighbor in get_valid_neighbors(current, world_state) {
        let tentative_g = map.get(g_score, current) + distance(current, neighbor)
        
        if tentative_g < map.get(g_score, neighbor) {
          map.insert(came_from, neighbor, current)
          map.insert(g_score, neighbor, tentative_g)
          let score = tentative_g + heuristic(neighbor, goal)
          map.insert(f_score, neighbor, score)
          
          if not priority_queue.contains(open_set, neighbor) {
            priority_queue.insert(open_set, neighbor, score)
          }
        }
      }
      
      search(priority_queue.pop(open_set))
    }
  }
  
  search(priority_queue.pop(open_set))
}