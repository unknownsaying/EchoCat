// src/minemind/nlp.gleam
import gleam/string

pub type Intent {
  BuildRequest(structure: String, location: Option(Position))
  ResourceRequest(resource: String, quantity: Int)
  NavigationTo(location: String)
  CraftRequest(item: String)
  CombatStrategy(mob: String)
  Question(about: String)
}

pub fn parse_natural_language(
  message: String,
  context: WorldContext
) -> Result(Intent, String) {
  let tokens = tokenize(message)
  let lowercase = string.lowercase(message)
  
  // Simple intent recognition (could be extended with ML)
  case tokens {
    ["build", structure, ..] -> 
      Ok(BuildRequest(structure, None))
    
    ["where", "is", resource] ->
      Ok(ResourceRequest(resource, 1))
    
    ["go", "to", location] ->
      Ok(NavigationTo(location))
    
    ["how", "to", "craft", item] ->
      Ok(CraftRequest(item))
    
    ["fight", mob] ->
      Ok(CombatStrategy(mob))
    
    _ ->
      // Use pattern matching for common questions
      if string.contains(lowercase, "what is") {
        let topic = extract_topic(message)
        Ok(Question(topic))
      } else {
        Error("Intent not recognized")
      }
  }
}