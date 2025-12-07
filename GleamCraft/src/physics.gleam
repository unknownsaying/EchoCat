// src/gleamcraft/physics/collision.gleam
import gleam/list
import gleam/map

pub type AABB {
  AABB(
    min: Vector3,
    max: Vector3
  )
}

pub type Ray {
  Ray(
    origin: Vector3,
    direction: Vector3,
    length: Float
  )
}

pub type CollisionResult {
  CollisionResult(
    collides: Bool,
    normal: Vector3,
    penetration: Float,
    block_position: Option(Position)
  )
}

pub fn check_collision(
  entity_aabb: AABB,
  world: World
) -> CollisionResult {
  // Get all blocks within entity's bounding box
  let block_positions = get_blocks_in_aabb(entity_aabb, world)
  
  list.fold(
    block_positions,
    CollisionResult(False, vector3.zero(), 0.0, None),
    fn(block_pos, result) {
      case block_at(block_pos, world) {
        Some(block) if block.is_solid ->
          let block_aabb = aabb_from_block(block)
          case aabb_intersection(entity_aabb, block_aabb) {
            Some(intersection) ->
              CollisionResult(
                True,
                intersection.normal,
                intersection.depth,
                Some(block.position)
              )
            None -> result
          }
        _ -> result
      }
    }
  )
}

pub fn ray_cast(
  ray: Ray,
  world: World,
  max_distance: Float
) -> Option({Position, Vector3}) {
  // DDA (Digital Differential Analyzer) algorithm for voxel traversal
  let step = vector3.sign(ray.direction)
  let t_delta = vector3.abs(vector3.divide(vector3.one(), ray.direction))
  let current_block = vector3.floor(ray.origin)
  
  fn traverse(t, current, step, t_delta, side_dist) {
    if t > max_distance {
      None
    } else {
      case block_at(current, world) {
        Some(block) if block.is_solid ->
          Some({current, get_normal(side_dist)})
        _ ->
          let next = if side_dist.x < side_dist.y && side_dist.x < side_dist.z {
            {current with x: current.x + step.x, side_dist with x: side_dist.x + t_delta.x}
          } else if side_dist.y < side_dist.z {
            {current with y: current.y + step.y, side_dist with y: side_dist.y + t_delta.y}
          } else {
            {current with z: current.z + step.z, side_dist with z: side_dist.z + t_delta.z}
          }
          traverse(t + 0.1, next.current, step, t_delta, next.side_dist)
      }
    }
  }
  
  traverse(0.0, current_block, step, t_delta, calculate_side_dist(ray.origin, current_block, step, t_delta))
}