// src/rl_agent/algorithms/hrl.gleam
pub type HRLAgent {
  HRLAgent(
    meta_controller: NeuralNetwork,  // High-level policy
    skill_library: Map(SkillId, NeuralNetwork),  // Low-level skills
    skill_selector: NeuralNetwork,   // Skill selector
    current_skill: Option(SkillId),
    skill_steps: Int
  )
}

pub type Skill {
  Skill(
    id: SkillId,
    precondition: State -> Bool,
    termination: State -> Bool,
    policy: NeuralNetwork,
    max_duration: Int
  )
}

pub type SkillId {
  MineBlock
  PlaceBlock
  NavigateTo
  AttackMob
  CollectItem
  CraftItem
}

pub fn select_skill(agent: HRLAgent, state: State, goal: Goal) -> SkillId {
  // Meta-controller selects which skill to use
  let skill_probs = forward_pass(agent.meta_controller, concatenate(state, goal))
  sample_from_distribution(skill_probs)
}

pub fn execute_skill(
  agent: HRLAgent,
  skill: SkillId,
  state: State,
  steps: Int
) -> #(List(Action), State) {
  if steps >= agent.skill_steps || skill.termination(state) {
    #([], state)
  } else {
    // Low-level policy executes primitive actions
    let action = forward_pass(agent.skill_library[skill], state)
    let next_state = simulate_action(state, action)
    let #(remaining_actions, final_state) = execute_skill(agent, skill, next_state, steps + 1)
    #([action] ++ remaining_actions, final_state)
  }
}