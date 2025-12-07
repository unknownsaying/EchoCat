// src/rl_agent/environment/minecraft_env.gleam
pub type MinecraftEnv {
  MinecraftEnv(
    world: World,
    player: Player,
    task: Task,
    step_count: Int,
    max_steps: Int
  )
}

pub type Task {
  CollectResource(resource: BlockId, quantity: Int)
  BuildStructure(structure: Structure)
  Survive(duration: Int)
  DefeatMob(mob_type: MobType)
  ExploreArea(area: AABB)
}

pub type Observation {
  Observation(
    voxel_grid: Tensor(shape: [10, 10, 10, 4]),  // Local block grid + metadata
    inventory: Map(ItemId, Int),
    health: Float,
    hunger: Float,
    position: Vector3,
    task_progress: TaskProgress
  )
}

pub type ActionSpace {
  ActionSpace(
    movements: List(Movement),
    interactions: List(Interaction),
    crafting: List(Recipe),
    inventory_actions: List(InventoryAction)
  )
}

pub fn step(env: MinecraftEnv, action: Action) -> #(MinecraftEnv, Observation, Float, Bool) {
  // Execute action in the world
  let updated_world = execute_action(env.world, env.player, action)
  
  // Calculate reward based on task
  let reward = calculate_reward(env, action, updated_world)
  
  // Check if episode is done
  let done = env.step_count >= env.max_steps || is_task_complete(env.task, updated_world) || env.player.health <= 0.0
  
  // Create new observation
  let observation = get_observation(updated_world, env.player)
  
  let updated_env = MinecraftEnv(
    world: updated_world,
    player: update_player(env.player, action, updated_world),
    task: env.task,
    step_count: env.step_count + 1,
    max_steps: env.max_steps
  )
  
  #(updated_env, observation, reward, done)
}

fn calculate_reward(env: MinecraftEnv, action: Action, world: World) -> Float {
  // Sparse rewards for task completion
  let task_reward = case env.task {
    CollectResource(resource, quantity) ->
      let collected = get_collected_count(env.player, resource, world)
      float.from_int(collected) * 10.0
    
    BuildStructure(structure) ->
      let progress = calculate_build_progress(structure, world)
      progress * 100.0
    
    Survive(duration) ->
      float.from_int(env.step_count) * 0.1
    
    DefeatMob(mob_type) ->
      let defeated = get_defeated_count(env.player, mob_type, world)
      float.from_int(defeated) * 50.0
    
    ExploreArea(area) ->
      let explored = calculate_explored_area(env.player, area, world)
      explored * 20.0
  }
  
  // Dense rewards for healthy behavior
  let health_penalty = if env.player.health < 5.0 { -10.0 } else { 0.0 }
  let hunger_penalty = if env.player.hunger > 80.0 { -5.0 } else { 0.0 }
  
  // Curiosity bonus for novel states
  let curiosity_bonus = calculate_curiosity_bonus(env, world)
  
  task_reward + health_penalty + hunger_penalty + curiosity_bonus
}