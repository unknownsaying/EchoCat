// src/main.gleam
import gleam/io
import gleam/erlang
import gleam/option.{None, Some}
import gleam/list
import gleam/map

pub fn main() {
  io.println("Starting GleamCraft RL...")
  
  // Initialize world
  let world = generate_world(42)
  let player = create_player("RL_Agent", {x: 0.0, y: 70.0, z: 0.0})
  
  // Initialize RL environment
  let env = MinecraftEnv(
    world: world,
    player: player,
    task: CollectResource(Stone, 64),
    step_count: 0,
    max_steps: 10000
  )
  
  // Initialize PPO agent
  let agent = create_ppo_agent(
    state_size: 10 * 10 * 10 * 4 + 20,  // Voxel grid + inventory/status
    action_size: 50,  // Movement + interactions + crafting
    learning_rate: 0.0003,
    clip_epsilon: 0.2
  )
  
  // Training parameters
  let training_episodes = 1000
  let steps_per_episode = 1000
  
  // Training loop
  let trained_agent = train_loop(agent, env, training_episodes, steps_per_episode)
  
  // Save trained model
  save_model(trained_agent, "models/trained_agent.gleam")
  
  // Start interactive mode with trained agent
  start_interactive_mode(world, trained_agent)
}

fn train_loop(agent, env, episodes_remaining, steps_per_episode) {
  if episodes_remaining <= 0 {
    agent
  } else {
    // Collect trajectories
    let trajectories = list.range(0, 10)
    |> list.map(fn(_) {
      collect_trajectory(agent, env.reset(), steps_per_episode)
    })
    
    // Update agent
    let updated_agent = update_agent(agent, trajectories)
    
    // Log progress
    let avg_reward = calculate_average_reward(trajectories)
    io.println("Episode: " <> int.to_string(1000 - episodes_remaining) <> 
               " | Avg Reward: " <> float.to_string(avg_reward))
    
    // Continue training
    train_loop(updated_agent, env, episodes_remaining - 1, steps_per_episode)
  }
}

fn start_interactive_mode(world, agent) {
  // Game loop
  fn game_loop(world, agent, step) {
    // Get current observation
    let observation = get_observation(world, world.player)
    
    // Agent chooses action
    let action = select_action(agent, observation)
    
    // Execute action
    let updated_world = execute_action(world, action)
    
    // Render (via ports to JavaScript)
    render_world(updated_world)
    
    // Continue
    erlang.process.sleep(50)  // ~20 FPS
    game_loop(updated_world, agent, step + 1)
  }
  
  game_loop(world, agent, 0)
}