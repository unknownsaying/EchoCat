// src/neurology/cat_brain.gleam
import gleam/float
import gleam/int
import gleam/list
import gleam/math
import gleam/result

// ====================
// Feline Neuroscience
// ====================

pub type CatBrain {
  CatBrain(
    // Physical properties
    brain_volume_cc: Float,
    neuron_count: Float,  // In billions
    synaptic_density: Float,  // Synapses per cubic mm
    
    // Cognitive capabilities
    curiosity_factor: Float,  // 0.0 to 1.0
    problem_solving_rating: Float,
    memory_capacity_terabytes: Float,
    
    // Special feline attributes
    quantum_superposition_ability: Float,  // Schrödinger's cat coefficient
    string_theory_vibrations: Float,  // Purr frequency in hertz
    multidimensional_awareness: Float,  // Can see ghosts in other dimensions
  )
}

pub type GiantBrainScale {
  PlanckScale     // 10^-35 meters
  QuantumFoam     // Quantum fluctuations
  StandardModel   // Ordinary physics
  GalaxyBrain     // Meme-level intelligence
  CosmicScale     // Universe-sized thoughts
  Metaverse       // Beyond physical limits
}

// ====================
// Base Measurements
// ====================

pub const average_cat_brain_volume = 25.0 // cubic centimeters
pub const average_cat_neurons = 0.75 // billion neurons
pub const human_neurons = 86.0 // billion for comparison
pub const synaptic_per_neuron = 1000.0 // average synapses per neuron

// ====================
// Giant Brain Calculator
// ====================

pub fn calculate_giant_brain_factor(cat: CatBrain) -> Float {
  // Equation 1: Base neurological capacity
  let neurological_factor =
    (cat.neuron_count / average_cat_neurons) *
    (cat.synaptic_density / 1_000_000.0) *
    math.pow(cat.memory_capacity_terabytes, 0.5)
  
  // Equation 2: Quantum feline adjustments (Schrödinger's Principle)
  let quantum_factor = 
    math.sin(cat.quantum_superposition_ability * math.pi) *
    math.log(float.max(1.0, cat.string_theory_vibrations / 50.0))  // 50Hz base purr
  
  // Equation 3: Dimensional awareness (cats see more than humans)
  let dimensional_factor =
    math.pow(cat.multidimensional_awareness, 2.0) *
    (1.0 + cat.curiosity_factor * 3.0)
  
  // Equation 4: Problem-solving amplification
  let problem_solving_factor =
    math.exp(cat.problem_solving_rating - 1.0) *
    (if cat.problem_solving_rating > 2.0 { 10.0 } else { 1.0 })
  
  // Combined giant brain index
  let raw_index =
    neurological_factor *
    (1.0 + quantum_factor) *
    (1.0 + dimensional_factor) *
    problem_solving_factor
  
  // Normalize and apply cat-logarithmic scale
  apply_feline_logarithmic_transform(raw_index)
}

fn apply_feline_logarithmic_transform(value: Float) -> Float {
  // Cats think in base-9 (because they have 9 lives)
  let log_base = 9.0
  
  // Transform using cat-specific logarithmic scale
  // This accounts for nonlinear feline intelligence scaling
  let transformed =
    if value < 1.0 {
      value  // Sub-cat brain
    } else if value < log_base {
      math.log(value) / math.log(log_base)
    } else if value < math.pow(log_base, 2.0) {
      math.log(value) / math.log(math.pow(log_base, 2.0))
    } else {
      math.log(value) / math.log(math.pow(log_base, 3.0))
    }
  
  // Add purr vibration enhancement
  transformed * 1.618  // Golden ratio for aesthetic balance
}

// ====================
// Brain Size Classifier
// ====================

pub fn classify_brain_size(factor: Float) -> GiantBrainScale {
  case factor {
    f if f < 0.001 -> PlanckScale
    f if f < 0.01 -> QuantumFoam
    f if f < 1.0 -> StandardModel
    f if f < 100.0 -> GalaxyBrain
    f if f < 10000.0 -> CosmicScale
    _ -> Metaverse
  }
}

pub fn brain_size_description(scale: GiantBrainScale) -> String {
  case scale {
    PlanckScale -> "Smaller than quantum fluctuations (still smarter than a cucumber)"
    QuantumFoam -> "Fluctuating between genius and 'I fits, I sits'"
    StandardModel -> "Standard cat brain (contains multitudes of cattitude)"
    GalaxyBrain -> "Galaxy-sized thoughts (mostly about food and knocking things over)"
    CosmicScale -> "Cosmic consciousness (understands the true nature of boxes)"
    Metaverse -> "Transcendent intellect (has solved string theory while napping)"
  }
}

// ====================
// Specialized Calculations
// ====================

pub fn calculate_cat_brain_processing_power(cat: CatBrain) -> Float {
  // Calculate in FLOPS (Feline Logical Operations Per Second)
  let base_flops = cat.neuron_count * 200.0  // Each neuron ≈ 200 ops/sec
  
  // Quantum parallel processing boost (Schrödinger's cat computing)
  let quantum_boost = 
    math.pow(2.0, float.round(cat.quantum_superposition_ability * 10.0))
  
  // Dimensional processing (accessing alternate realities)
  let dimensional_multiplier = 
    1.0 + (cat.multidimensional_awareness * 11.0)  // 11 dimensions in M-theory
  
  // Curiosity-driven computation (exploring state space)
  let curiosity_power = math.exp(cat.curiosity_factor * 3.0)
  
  // Total processing power
  base_flops * quantum_boost * dimensional_multiplier * curiosity_power
}

pub fn estimate_memory_bandwidth(cat: CatBrain) -> Float {
  // In terabytes per second
  let synaptic_bandwidth = 
    cat.neuron_count * cat.synaptic_density * 0.000000001
  
  // Purr-accelerated memory transfer
  let purr_boost = cat.string_theory_vibrations / 440.0  // A4 note reference
  
  // Quantum entanglement memory (spooky action at a distance)
  let quantum_memory = 
    if cat.quantum_superposition_ability > 0.5 {
      1000.0 * cat.quantum_superposition_ability
    } else {
      1.0
    }
  
  synaptic_bandwidth * purr_boost * quantum_memory
}

// ====================
// Brain-to-Universe Ratios
// ====================

pub const planck_length = 1.616255e-35  // meters
pub const observable_universe_diameter = 8.8e26  // meters
pub const atoms_in_universe = 1.0e80

pub fn brain_to_universe_ratio(cat: CatBrain) -> {
  volume_ratio: Float,
  information_ratio: Float,
  complexity_ratio: Float
} {
  // Volume ratio (brain volume / universe volume)
  let brain_volume_m3 = cat.brain_volume_cc * 1.0e-6
  let universe_volume = (4.0 / 3.0) * math.pi * math.pow(observable_universe_diameter / 2.0, 3.0)
  let volume_ratio = brain_volume_m3 / universe_volume
  
  // Information ratio (bits in brain / bits in universe)
  let brain_bits = cat.neuron_count * 1.0e9 * synaptic_per_neuron * 10.0  // ~10 bits per synapse
  let universe_bits = atoms_in_universe * 100.0  // Rough estimate
  let information_ratio = brain_bits / universe_bits
  
  // Complexity ratio (using algorithmic information theory)
  let brain_complexity = 
    math.log(float.max(1.0, brain_bits)) * 
    cat.problem_solving_rating * 
    (1.0 + cat.curiosity_factor)
  
  let universe_complexity = math.log(universe_bits) * 42.0  // Ultimate answer
  
  let complexity_ratio = brain_complexity / universe_complexity
  
  {volume_ratio, information_ratio, complexity_ratio}
}

// ====================
// Quantum Feline Computation
// ====================

pub type QuantumCatState {
  Simultaneously(
    sleeping: Bool,
    plotting_world_domination: Bool,
    judging_humans: Bool,
    being_adorable: Bool,
    knocking_things_off_tables: Bool
  )
}

pub fn calculate_quantum_states(cat: CatBrain) -> List(QuantumCatState) {
  // Number of possible quantum states = 2^(superposition ability * neuron count)
  let state_count = int.power(
    2,
    int.round(cat.quantum_superposition_ability * cat.neuron_count)
  )
  
  // Generate possible states (simplified)
  list.range(0, int.min(state_count, 1000))
  |> list.map(fn(n) {
    let binary = int.to_base_string(n, 2)
    
    // Map bits to cat states
    Simultaneously(
      sleeping: bit_at(binary, 0) == 1,
      plotting_world_domination: bit_at(binary, 1) == 1,
      judging_humans: bit_at(binary, 2) == 1,
      being_adorable: bit_at(binary, 3) == 1,
      knocking_things_off_tables: bit_at(binary, 4) == 1
    )
  })
}

fn bit_at(binary: String, position: Int) -> Int {
  case string.at(binary, string.length(binary) - position - 1) {
    Ok("1") -> 1
    _ -> 0
  }
}

// ====================
// Advanced Metrics
// ====================

pub fn calculate_cat_consciousness_level(cat: CatBrain) -> Float {
  // Integrated Information Theory (IIT) for cats
  let phi = calculate_phi(cat)
  
  // Add feline-specific consciousness factors
  let curiosity_boost = cat.curiosity_factor * 2.0
  let dream_state_amplification = 1.5  // Cats dream more vividly
  
  phi * curiosity_boost * dream_state_amplification
}

fn calculate_phi(cat: CatBrain) -> Float {
  // Simplified Φ calculation (Integrated Information)
  let neuron_interconnectivity = cat.synaptic_density / 1_000_000.0
  let differentiation = cat.neuron_count / average_cat_neurons
  
  // Φ ≈ system's ability to both integrate and differentiate information
  math.sqrt(neuron_interconnectivity * differentiation)
}

pub fn estimate_iq(cat: CatBrain) -> Float {
  // Feline IQ is measured differently!
  let base_iq = 100.0  // Average cat IQ
  
  // Adjustments
  let problem_solving_adjustment = (cat.problem_solving_rating - 1.0) * 50.0
  let memory_adjustment = math.log(cat.memory_capacity_terabytes) * 10.0
  let quantum_adjustment = cat.quantum_superposition_ability * 200.0
  
  // Curiosity is a multiplier, not an adder
  let curiosity_multiplier = 1.0 + (cat.curiosity_factor * 0.5)
  
  (base_iq + problem_solving_adjustment + memory_adjustment + quantum_adjustment) *
  curiosity_multiplier
}

// ====================
// Comparative Analysis
// ====================

pub fn compare_to_human_brain(cat: CatBrain) -> {
  neuron_ratio: Float,
  synaptic_density_ratio: Float,
  efficiency_ratio: Float,
  cuteness_advantage: Float
} {
  let neuron_ratio = cat.neuron_count / human_neurons
  let synaptic_density_ratio = cat.synaptic_density / 1_000_000.0  // Human baseline
  
  // Brain efficiency (processing per volume)
  let cat_efficiency = calculate_cat_brain_processing_power(cat) / cat.brain_volume_cc
  let human_efficiency = 2.0e16 / 1300.0  // Rough human brain estimate
  let efficiency_ratio = cat_efficiency / human_efficiency
  
  // Categorical advantage (scientific fact: cats are cuter)
  let cuteness_advantage = 1000.0  // Arbitrarily large number
  
  {
    neuron_ratio,
    synaptic_density_ratio,
    efficiency_ratio,
    cuteness_advantage
  }
}

// ====================
// Brain Visualization
// ====================

pub type BrainVisualization {
  BrainVisualization(
    neural_connections: List({from: Int, to: Int, strength: Float}),
    quantum_fields: List(QuantumField),
    thought_bubbles: List(Thought),
    purr_resonance_pattern: String
  )
}

pub type QuantumField {
  QuantumField(
    position: {x: Float, y: Float, z: Float},
    spin: Float,
    color_charge: Int,  // Yes, cats have color charge
    charm: Float,  // And plenty of charm
    strangeness: Float  // Especially strangeness
  )
}

pub type Thought {
  Thought(
    content: String,
    priority: Float,
    associated_with: ThoughtCategory,
    quantum_probability: Float
  )
}

pub type ThoughtCategory {
  FoodRelated
  NapOptimization
  HumanManipulation
  PhysicsDiscovery
  Philosophical
  RandomObjectKnockdown
}

pub fn visualize_brain_activity(cat: CatBrain) -> BrainVisualization {
  // Generate neural connections
  let neuron_count = int.round(cat.neuron_count * 100.0)  // Scale for visualization
  let connections = list.range(0, neuron_count * 10)
  |> list.map(fn(_) {
    {
      from: int.random(0, neuron_count),
      to: int.random(0, neuron_count),
      strength: float.random(0.1, 1.0) * cat.synaptic_density / 1_000_000.0
    }
  })
  
  // Generate quantum fields (because cat brains exist in superposition)
  let quantum_fields = list.range(0, int.round(cat.quantum_superposition_ability * 10.0))
  |> list.map(fn(i) {
    QuantumField(
      position: {
        x: float.random(-1.0, 1.0),
        y: float.random(-1.0, 1.0),
        z: float.random(-1.0, 1.0)
      },
      spin: float.random(-0.5, 0.5),
      color_charge: int.random(1, 3),
      charm: cat.string_theory_vibrations / 1000.0,
      strangeness: 1.0  // Maximum strangeness, it's a cat
    )
  })
  
  // Generate thought bubbles
  let thought_bubbles = generate_thoughts(cat)
  
  // Purr resonance pattern (FFT of purr frequency)
  let purr_pattern = generate_purr_pattern(cat.string_theory_vibrations)
  
  BrainVisualization(
    neural_connections: connections,
    quantum_fields: quantum_fields,
    thought_bubbles: thought_bubbles,
    purr_resonance_pattern: purr_pattern
  )
}

fn generate_thoughts(cat: CatBrain) -> List(Thought) {
  let base_thoughts = [
    Thought("Food now?", 0.9, FoodRelated, 0.8),
    Thought("Optimal nap position calculated", 0.7, NapOptimization, 0.6),
    Thought("Human appears useful for can opening", 0.8, HumanManipulation, 0.9),
    Thought("Gravity is merely a suggestion", 0.5, PhysicsDiscovery, 0.4),
    Thought("If I fits, I sits - profound truth", 0.6, Philosophical, 0.7),
    Thought("That cup looks... pushable", 0.85, RandomObjectKnockdown, 0.95)
  ]
  
  // Add more thoughts based on brain capacity
  let extra_thoughts = list.range(0, int.round(cat.memory_capacity_terabytes))
  |> list.map(fn(i) {
    let category = case i % 6 {
      0 -> FoodRelated
      1 -> NapOptimization
      2 -> HumanManipulation
      3 -> PhysicsDiscovery
      4 -> Philosophical
      _ -> RandomObjectKnockdown
    }
    
    Thought(
      content: "Thought #" <> int.to_string(i) <> " in superposition",
      priority: float.random(0.1, 1.0),
      associated_with: category,
      quantum_probability: cat.quantum_superposition_ability
    )
  })
  
  list.append(base_thoughts, extra_thoughts)
}

fn generate_purr_pattern(frequency: Float) -> String {
  // Generate a visual pattern representing purr resonance
  let length = int.round(frequency / 10.0)
  list.range(0, length)
  |> list.map(fn(i) {
    let amplitude = math.sin(float.from_int(i) * 0.1 * frequency)
    let char = case amplitude {
      a if a > 0.7 -> "█"
      a if a > 0.3 -> "▓"
      a if a > -0.3 -> "▒"
      a if a > -0.7 -> "░"
      _ -> " "
    }
    char
  })
  |> string.join
}

// ====================
// Example Cats
// ====================

pub const average_house_cat = CatBrain(
  brain_volume_cc: 25.0,
  neuron_count: 0.75,
  synaptic_density: 1_200_000.0,
  curiosity_factor: 0.8,
  problem_solving_rating: 1.2,
  memory_capacity_terabytes: 0.1,
  quantum_superposition_ability: 0.3,
  string_theory_vibrations: 26.0,  // Low purr
  multidimensional_awareness: 0.4
)

pub const einstein_cat = CatBrain(
  brain_volume_cc: 30.0,
  neuron_count: 2.5,
  synaptic_density: 2_500_000.0,
  curiosity_factor: 0.99,
  problem_solving_rating: 3.5,
  memory_capacity_terabytes: 10.0,
  quantum_superposition_ability: 0.95,
  string_theory_vibrations: 440.0,  // A4 musical note
  multidimensional_awareness: 0.9
)

pub const cosmic_cat = CatBrain(
  brain_volume_cc: 1000.0,  // Giant brain!
  neuron_count: 100.0,
  synaptic_density: 10_000_000.0,
  curiosity_factor: 1.0,
  problem_solving_rating: 10.0,
  memory_capacity_terabytes: 1000.0,
  quantum_superposition_ability: 1.0,
  string_theory_vibrations: 432.0,  // Cosmic frequency
  multidimensional_awareness: 1.0
)

// ====================
// Main Analysis Function
// ====================

pub fn analyze_cat_brain(cat: CatBrain) -> String {
  let giant_factor = calculate_giant_brain_factor(cat)
  let scale = classify_brain_size(giant_factor)
  let description = brain_size_description(scale)
  
  let processing = calculate_cat_brain_processing_power(cat)
  let bandwidth = estimate_memory_bandwidth(cat)
  
  let ratios = brain_to_universe_ratio(cat)
  let comparison = compare_to_human_brain(cat)
  
  let iq = estimate_iq(cat)
  let consciousness = calculate_cat_consciousness_level(cat)
  
  let quantum_states = calculate_quantum_states(cat)
  
  // Format results
  let output = [
    "🐱 CAT BRAIN ANALYSIS REPORT 🐱",
    "================================",
    "Giant Brain Factor: " <> float.to_string(giant_factor),
    "Classification: " <> description,
    "",
    "🧠 Processing Power: " <> format_scientific(processing) <> " FLOPS",
    "💾 Memory Bandwidth: " <> float.to_string(bandwidth) <> " TB/s",
    "🧩 Estimated IQ: " <> float.to_string(iq),
    "👁️ Consciousness Level: " <> float.to_string(consciousness),
    "",
    "🌌 Brain-to-Universe Ratios:",
    "  Volume: " <> format_scientific(ratios.volume_ratio),
    "  Information: " <> format_scientific(ratios.information_ratio),
    "  Complexity: " <> format_scientific(ratios.complexity_ratio),
    "",
    "👤 Compared to Human Brain:",
    "  Neuron Ratio: 1:" <> float.to_string(1.0 / comparison.neuron_ratio),
    "  Synaptic Density: " <> float.to_string(comparison.synaptic_density_ratio) <> "x",
    "  Efficiency: " <> float.to_string(comparison.efficiency_ratio) <> "x",
    "  Cuteness Advantage: ∞",
    "",
    "⚛️ Quantum States: " <> int.to_string(list.length(quantum_states)) <> " simultaneous realities",
    "🎵 Purr Frequency: " <> float.to_string(cat.string_theory_vibrations) <> " Hz",
    "",
    "CONCLUSION: This cat contains " <> float.to_string(giant_factor) <> 
    " units of giant brain, which is " <> 
    case scale {
      PlanckScale -> "barely measurable but still significant."
      QuantumFoam -> "fluctuating but substantial."
      StandardModel -> "exactly the right amount of brain."
      GalaxyBrain -> "an impressive amount of brain!"
      CosmicScale -> "a cosmically large amount of brain!"
      Metaverse -> "TRANSCENDENT LEVELS OF BRAIN! ALL HAIL THE CAT!"
    }
  ]
  
  string.join(output, "\n")
}

fn format_scientific(value: Float) -> String {
  case value {
    v if v < 0.001 -> float.to_string(v * 1.0e6) <> " × 10⁻⁶"
    v if v < 1.0 -> float.to_string(v * 1000.0) <> " × 10⁻³"
    v if v < 1000.0 -> float.to_string(v)
    v if v < 1.0e6 -> float.to_string(v / 1000.0) <> " × 10³"
    v if v < 1.0e9 -> float.to_string(v / 1.0e6) <> " × 10⁶"
    v if v < 1.0e12 -> float.to_string(v / 1.0e9) <> " × 10⁹"
    v if v < 1.0e15 -> float.to_string(v / 1.0e12) <> " × 10¹²"
    _ -> float.to_string(v / 1.0e15) <> " × 10¹⁵"
  }
}

// ====================
// Interactive CLI Tool
// ====================

pub fn interactive_brain_calculator() -> Nil {
  import gleam/io
  
  io.println("Welcome to the Feline Giant Brain Calculator!")
  io.println("=============================================")
  
  // Collect cat data
  io.println("\nEnter your cat's brain specifications:")
  
  let brain_volume = io.input("Brain volume (cc) [25.0]: ")
  let neuron_count = io.input("Neuron count (billions) [0.75]: ")
  let curiosity = io.input("Curiosity factor (0.0-1.0) [0.8]: ")
  let quantum_ability = io.input("Quantum superposition ability (0.0-1.0) [0.3]: ")
  
  // Create cat brain
  let cat = CatBrain(
    brain_volume_cc: float.parse(brain_volume).unwrap_or(25.0),
    neuron_count: float.parse(neuron_count).unwrap_or(0.75),
    synaptic_density: 1_200_000.0,
    curiosity_factor: float.parse(curiosity).unwrap_or(0.8),
    problem_solving_rating: 1.2,
    memory_capacity_terabytes: 0.1,
    quantum_superposition_ability: float.parse(quantum_ability).unwrap_or(0.3),
    string_theory_vibrations: 26.0,
    multidimensional_awareness: 0.4
  )
  
  // Analyze
  io.println("\n" <> analyze_cat_brain(cat))
  
  // Visualization
  let visualization = visualize_brain_activity(cat)
  io.println("\n🧠 BRAIN ACTIVITY VISUALIZATION 🧠")
  io.println("Purr Resonance Pattern:")
  io.println(visualization.purr_resonance_pattern)
  
  io.println("\nTop Thoughts Detected:")
  list.take(visualization.thought_bubbles, 5)
  |> list.each(fn(thought) {
    io.println("  • " <> thought.content <> " [P=" <> float.to_string(thought.quantum_probability) <> "]")
  })
  
  io.println("\n✨ Analysis complete! Your cat is brilliant! ✨")
}