// src/rl_agent/algorithms/ppo.gleam
import gleam/float
import gleam/list

pub type PPOAgent {
  PPOAgent(
    policy_network: NeuralNetwork,
    value_network: NeuralNetwork,
    optimizer: Optimizer,
    clip_epsilon: Float,
    entropy_coefficient: Float,
    discount_factor: Float,
    gae_lambda: Float
  )
}

pub type Trajectory {
  Trajectory(
    states: List(State),
    actions: List(Action),
    rewards: List(Float),
    values: List(Float),
    log_probs: List(Float)
  )
}

pub fn collect_trajectory(
  agent: PPOAgent,
  env: Environment,
  max_steps: Int
) -> Trajectory {
  fn loop(state, steps, acc) {
    if steps >= max_steps {
      acc
    } else {
      // Get action from policy network
      let action_distribution = forward_pass(agent.policy_network, state)
      let action = sample_from_distribution(action_distribution)
      let log_prob = log_probability(action_distribution, action)
      
      // Step environment
      let {next_state, reward, done} = env.step(action)
      let value = forward_pass(agent.value_network, state)
      
      let new_acc = Trajectory(
        list.append(acc.states, [state]),
        list.append(acc.actions, [action]),
        list.append(acc.rewards, [reward]),
        list.append(acc.values, [value]),
        list.append(acc.log_probs, [log_prob])
      )
      
      if done {
        new_acc
      } else {
        loop(next_state, steps + 1, new_acc)
      }
    }
  }
  
  loop(env.reset(), 0, Trajectory([], [], [], [], []))
}

pub fn calculate_advantages(trajectory: Trajectory) -> List(Float) {
  // Generalized Advantage Estimation (GAE)
  let rewards = trajectory.rewards
  let values = trajectory.values
  let next_values = list.drop(values, 1) ++ [0.0]
  
  list.zip_with(rewards, values, next_values, fn(reward, value, next_value) {
    let delta = reward + agent.discount_factor * next_value - value
    delta
  })
  |> calculate_gae(agent.gae_lambda)
}

pub fn update_agent(agent: PPOAgent, trajectories: List(Trajectory)) -> PPOAgent {
  // Combine all trajectories
  let batch = combine_trajectories(trajectories)
  let advantages = calculate_advantages(batch)
  let returns = calculate_returns(batch.rewards)
  
  // Multiple epochs of updates
  fn update_epoch(agent, epoch) {
    if epoch >= 4 {
      agent
    } else {
      // Calculate ratios and surrogate loss
      let new_log_probs = calculate_log_probs(agent.policy_network, batch.states, batch.actions)
      let ratios = list.zip_with(new_log_probs, batch.log_probs, fn(new, old) {
        float.exp(new - old)
      })
      
      let surrogate1 = list.zip_with(ratios, advantages, fn(ratio, advantage) {
        ratio * advantage
      })
      
      let surrogate2 = list.zip_with(ratios, advantages, fn(ratio, advantage) {
        float.clamp(ratio, 1.0 - agent.clip_epsilon, 1.0 + agent.clip_epsilon) * advantage
      })
      
      let policy_loss = list.map2(surrogate1, surrogate2, fn(s1, s2) {
        -float.min(s1, s2)
      })
      |> list.reduce(float.add, 0.0)
      
      // Calculate entropy bonus
      let entropies = calculate_entropy(agent.policy_network, batch.states)
      let entropy_bonus = list.reduce(float.add, entropies) * agent.entropy_coefficient
      
      // Value loss
      let new_values = forward_pass_batch(agent.value_network, batch.states)
      let value_loss = list.zip_with(new_values, returns, fn(value, return_) {
        0.5 * float.pow(value - return_, 2.0)
      })
      |> list.reduce(float.add, 0.0)
      
      // Total loss
      let total_loss = policy_loss - entropy_bonus + 0.5 * value_loss
      
      // Update networks
      let updated_policy = optimize(agent.policy_network, policy_loss, agent.optimizer)
      let updated_value = optimize(agent.value_network, value_loss, agent.optimizer)
      
      update_epoch(PPOAgent(..agent, policy_network: updated_policy, value_network: updated_value), epoch + 1)
    }
  }
  
  update_epoch(agent, 0)
}