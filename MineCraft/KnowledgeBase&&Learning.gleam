// src/minemind/knowledge.gleam
import gleam/map
import gleam/dict

pub type KnowledgeBase {
  KnowledgeBase(
    recipes: Map(String, Recipe),
    mob_behaviors: Map(String, MobBehavior),
    biome_resources: Map(String, List(String)),
    build_patterns: Map(String, Blueprint),
    player_preferences: Map(String, Preferences)
  )
}

pub fn learn_from_interaction(
  kb: KnowledgeBase,
  interaction: PlayerInteraction,
  outcome: Outcome
) -> KnowledgeBase {
  case interaction {
    BuildingAttempt(structure, success_rate) ->
      let updated = update_build_pattern(kb, structure, success_rate)
      KnowledgeBase(..kb, build_patterns: updated)
    
    ResourceGathering(resource, efficiency) ->
      let updated = update_resource_data(kb, resource, efficiency)
      KnowledgeBase(..kb, biome_resources: updated)
    
    CombatEncounter(mob, strategy, damage_taken) ->
      let updated = update_mob_behavior(kb, mob, strategy, damage_taken)
      KnowledgeBase(..kb, mob_behaviors: updated)
  }
}