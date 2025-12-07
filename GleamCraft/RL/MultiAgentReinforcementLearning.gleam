// src/rl_agent/algorithms/marl.gleam
pub type MultiAgentEnv {
  MultiAgentEnv(
    world: World,
    agents: Map(AgentId, AgentState),
    tasks: Map(TaskId, Task),
    collaborations: List(Collaboration)
  )
}

pub type MADDPGAgent {
  MADDPGAgent(
    actor: NeuralNetwork,
    critic: NeuralNetwork,
    target_actor: NeuralNetwork,
    target_critic: NeuralNetwork,
    replay_buffer: ReplayBuffer,
    agent_id: AgentId
  )
}

pub fn train_maddpg(
  agents: Map(AgentId, MADDPGAgent),
  env: MultiAgentEnv,
  episodes: Int
) -> Map(AgentId, MADDPGAgent) {
  fn train_episode(agents, env, episode) {
    if episode >= episodes {
      agents
    } else {
      // All agents act simultaneously
      let actions = map.map(agents, fn(agent) {
        let state = get_agent_observation(env, agent.agent_id)
        let action = forward_pass(agent.actor, state)
        {agent.agent_id: action}
      })
      
      // Step environment with all actions
      let {next_env, rewards, dones} = env.step(actions)
      
      // Store experiences in replay buffers
      let updated_agents = map.map(agents, fn(agent) {
        let experience = Experience(
          state: get_agent_observation(env, agent.agent_id),
          action: actions[agent.agent_id],
          reward: rewards[agent.agent_id],
          next_state: get_agent_observation(next_env, agent.agent_id),
          done: dones[agent.agent_id]
        )
        
        let updated_buffer = add_experience(agent.replay_buffer, experience)
        MADDPGAgent(..agent, replay_buffer: updated_buffer)
      })
      
      // Sample batches and update
      let trained_agents = map.map(updated_agents, fn(agent) {
        let batch = sample_batch(agent.replay_buffer)
        update_maddpg_agent(agent, batch, agents)  // Uses centralized critic
      })
      
      train_episode(trained_agents, next_env, episode + 1)
    }
  }
  
  train_episode(agents, env, 0)
}