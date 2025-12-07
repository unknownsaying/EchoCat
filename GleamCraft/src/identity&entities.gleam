// src/brand/visual_identity.gleam
import gleam/io
import gleam/string
import gleam/list

// ====================
// GLEAMCRAFT VISUAL IDENTITY
// Colors, Logos, Typography, and Design System
// ====================

pub type BrandColors {
  BrandColors(
    primary: ColorPalette,
    functional: ColorPalette,
    dimensions: DimensionColors,
    ui: UIColors,
    effects: EffectColors
  )
}

pub type ColorPalette {
  ColorPalette(
    main: RGB,
    light: RGB,
    dark: RGB,
    accent: RGB,
    complementary: RGB
  )
}

pub type RGB {
  RGB(r: Int, g: Int, b: Int)
}

pub const gleam_primary = ColorPalette(
  main: RGB(46, 204, 113),     // Emerald green (immutable)
  light: RGB(120, 224, 143),   // Light emerald
  dark: RGB(30, 163, 89),      // Dark emerald
  accent: RGB(155, 89, 182),   // Purple (functional)
  complementary: RGB(241, 196, 15)  // Yellow (warning/type)
)

pub const functional_colors = ColorPalette(
  main: RGB(52, 152, 219),     // Blue (pure functions)
  light: RGB(133, 193, 233),   // Light blue
  dark: RGB(32, 102, 148),     // Dark blue
  accent: RGB(230, 126, 34),   // Orange (side effects)
  complementary: RGB(231, 76, 60)  // Red (errors)
)

pub type DimensionColors {
  DimensionColors(
    overworld: ColorPalette,
    nether: ColorPalette,
    end: ColorPalette,
    quantum: ColorPalette
  )
}

pub const dimension_colors = DimensionColors(
  overworld: ColorPalette(
    main: RGB(120, 177, 89),    // Grass green
    light: RGB(170, 219, 140),
    dark: RGB(76, 119, 56),
    accent: RGB(84, 153, 199),  // Water blue
    complementary: RGB(189, 154, 93)  // Sand
  ),
  nether: ColorPalette(
    main: RGB(179, 48, 48),     // Lava red
    light: RGB(224, 116, 116),
    dark: RGB(128, 32, 32),
    accent: RGB(255, 159, 26),  // Blaze orange
    complementary: RGB(81, 46, 95)  // Netherrack purple
  ),
  end: ColorPalette(
    main: RGB(37, 36, 48),      // End stone gray
    light: RGB(84, 82, 104),
    dark: RGB(18, 17, 24),
    accent: RGB(169, 120, 211), // Purple chorus
    complementary: RGB(255, 216, 102)  // Dragon breath yellow
  ),
  quantum: ColorPalette(
    main: RGB(72, 52, 212),     // Quantum blue
    light: RGB(127, 110, 255),
    dark: RGB(40, 30, 150),
    accent: RGB(255, 64, 129),  // Pink superposition
    complementary: RGB(102, 255, 102)  // Green entanglement
  )
)

pub type UIColors {
  UIColors(
    background: RGB,
    foreground: RGB,
    success: RGB,
    warning: RGB,
    error: RGB,
    info: RGB,
    highlight: RGB
  )
}

pub const ui_colors = UIColors(
  background: RGB(26, 28, 36),     // Dark space
  foreground: RGB(224, 226, 232),  // Light text
  success: RGB(46, 204, 113),      // Success green
  warning: RGB(241, 196, 15),      // Warning yellow
  error: RGB(231, 76, 60),         // Error red
  info: RGB(52, 152, 219),         // Info blue
  highlight: RGB(155, 89, 182)     // Highlight purple
)

pub type EffectColors {
  EffectColors(
    water: RGB,
    lava: RGB,
    portal: RGB,
    enchantment: RGB,
    redstone: RGB
  )
}

pub const effect_colors = EffectColors(
  water: RGB(61, 147, 209),
  lava: RGB(207, 96, 36),
  portal: RGB(118, 70, 175),
  enchantment: RGB(180, 220, 255),
  redstone: RGB(255, 0, 0)
)

pub const official_colors = BrandColors(
  primary: gleam_primary,
  functional: functional_colors,
  dimensions: dimension_colors,
  ui: ui_colors,
  effects: effect_colors
)

// ====================
// Typography System
// ====================

pub type Typography {
  Typography(
    heading: Font,
    body: Font,
    code: Font,
    ui: Font,
    special: Font
  )
}

pub type Font {
  Font(
    name: String,
    size: Int,
    weight: FontWeight,
    style: FontStyle
  )
}

pub type FontWeight {
  Light
  Regular
  Medium
  Bold
  Black
}

pub type FontStyle {
  Normal
  Italic
  Monospace
  Decorative
}

pub const official_typography = Typography(
  heading: Font("Quantum Sans", 24, Bold, Normal),
  body: Font("Gleam Serif", 16, Regular, Normal),
  code: Font("Monad Mono", 14, Regular, Monospace),
  ui: Font("Functional Sans", 15, Medium, Normal),
  special: Font("Pattern Glyphs", 18, Regular, Decorative)
)

// ====================
// Logo System
// ====================

pub type Logo {
  Logo(
    primary: String,  // ASCII/Unicode representation
    variant: LogoVariant,
    usage_rules: List(String),
    animation: Option(LogoAnimation)
  )
}

pub type LogoVariant {
  Standard
  Minimal
  Animated
  Glyph
  FullColor
}

pub const primary_logo = Logo(
  primary: """
       ╔════════════════════════╗
       ║      GLEAMCRAFT        ║
       ║    ░█▀▀░▀█▀░█░░░█▀▀    ║
       ║    ░▀▀█░░█░░█░░░█▀▀    ║
       ║    ░▀▀▀░░▀░░▀▀▀░▀▀▀    ║
       ║        WORLD 1.0       ║
       ╚════════════════════════╝
  """,
  variant: Standard,
  usage_rules: [
    "Use on official documentation",
    "Use as title screen logo",
    "Do not distort or recolor",
    "Maintain clear space around logo"
  ],
  animation: Some(LogoAnimation("Pulse with functional glow", 2.0))
)

pub const minimal_logo = Logo(
  primary: """
      ╭────────────────╮
      │   ╔═══╗ ╔╗ ╔╗  │
      │   ║╔══╝ ║║ ║║  │
      │   ║╚══╗ ║║ ║║  │
      │   ║╔══╝ ║║ ║║  │
      │   ║╚══╗ ║╚═╝║  │
      │   ╚═══╝ ╚═══╝  │
      ╰────────────────╯
  """,
  variant: Minimal,
  usage_rules: [
    "Use for loading screens",
    "Use as favicon",
    "Use in small spaces"
  ],
  animation: None
)

// ====================
// Iconography
// ====================

pub type IconSet {
  IconSet(
    blocks: Map(BlockType, String),
    items: Map(ItemType, String),
    entities: Map(EntityType, String),
    ui: Map(UIIcon, String),
    status: Map(StatusEffect, String)
  )
}

pub const game_icons = IconSet(
  blocks: map.from_list([
    #(Gleamstone, "◇"),
    #(LambdaLog, "λ"),
    #(MonadOre, "M"),
    #(TupleBlock, "()"),
    #(FunctionCrystal, "ƒ"),
    #(PatternGlass, "▢")
  ]),
  items: map.from_list([
    #(GleamPickaxe, "⛏"),
    #(LambdaSword, "⚔"),
    #(FoldBow, "🏹"),
    #(MapShovel, "🛠"),
    #(FilterHoe, "🔍")
  ]),
  entities: map.from_list([
    #(Player, "👤"),
    #(Gleamerian, "👽"),
    #(LambdaLizard, "🦎"),
    #(MonadMoth, "🦋"),
    #(CurryBird, "🐦")
  ]),
  ui: map.from_list([
    #(Inventory, "🎒"),
    #(Crafting, "⚒"),
    #(Settings, "⚙"),
    #(Multiplayer, "👥"),
    #(Singleplayer, "👤"),
    #(Quit, "🚪")
  ]),
  status: map.from_list([
    #(Speed, "⚡"),
    #(Strength, "💪"),
    #(Invisibility, "👻"),
    #(Regeneration, "❤"),
    #(Poison, "☠"),
    #(WaterBreathing, "🌊")
  ])
)

// ====================
// Animation System
// ====================

pub type AnimationStyle {
  AnimationStyle(
    movement: MovementStyle,
    transitions: TransitionStyle,
    effects: EffectAnimation,
    ui: UIAnimation
  )
}

pub const gleam_animation = AnimationStyle(
  movement: MovementStyle(
    smooth: True,
    easing: "cubic-bezier(0.4, 0.0, 0.2, 1)",
    physics_based: True
  ),
  transitions: TransitionStyle(
    fade_duration: 0.3,
    slide_duration: 0.4,
    scale_duration: 0.2
  ),
  effects: EffectAnimation(
    particle_lifetime: 2.0,
    wave_speed: 1.5,
    glow_intensity: 0.8
  ),
  ui: UIAnimation(
    hover_scale: 1.05,
    click_feedback: True,
    tooltip_delay: 0.5
  )
)

// ====================
// Brand Guidelines
// ====================

pub type BrandGuidelines {
  BrandGuidelines(
    logo_usage: LogoGuidelines,
    color_palette: ColorGuidelines,
    typography_rules: TypographyRules,
    spacing_system: SpacingSystem,
    component_library: ComponentLibrary
  )
}

pub const official_guidelines = BrandGuidelines(
  logo_usage: LogoGuidelines(
    minimum_size: 32,
    clear_space: 8,
    allowed_backgrounds: ["Dark", "Light", "Primary"],
    prohibited_uses: ["Distorted", "Recolored", "Animated incorrectly"]
  ),
  color_palette: ColorGuidelines(
    primary_usage: "Buttons, important actions",
    functional_usage: "Code, type indicators",
    dimension_usage: "World-specific UI elements",
    accessibility: "Ensure contrast ratio of 4.5:1 for text"
  ),
  typography_rules: TypographyRules(
    heading_sizes: [24, 20, 18, 16],
    line_height: 1.5,
    letter_spacing: 0.5,
    paragraph_spacing: 16
  ),
  spacing_system: SpacingSystem(
    unit: 4,
    small: 4,
    medium: 8,
    large: 16,
    xlarge: 32
  ),
  component_library: ComponentLibrary(
    buttons: True,
    cards: True,
    modals: True,
    tooltips: True,
    progress_bars: True
  )
)

// ====================
// Export Functions
// ====================

pub fn get_color_palette(dimension: String) -> ColorPalette {
  case dimension {
    "overworld" -> official_colors.dimensions.overworld
    "nether" -> official_colors.dimensions.nether
    "end" -> official_colors.dimensions.end
    "quantum" -> official_colors.dimensions.quantum
    _ -> gleam_primary
  }
}

pub fn render_logo(variant: LogoVariant) -> String {
  case variant {
    Standard -> primary_logo.primary
    Minimal -> minimal_logo.primary
    Animated -> primary_logo.primary <> "\n✨"
    Glyph -> "λ⚡"
    FullColor -> primary_logo.primary <> " (Full Color)"
  }
}

pub fn print_brand_style_guide() -> Nil {
  io.println("""
  ╔══════════════════════════════════════════════╗
  ║        GLEAMCRAFT VISUAL STYLE GUIDE         ║
  ╚══════════════════════════════════════════════╝
  
  PRIMARY COLORS:
  • Gleam Green: #2ecc71 (RGB 46, 204, 113)
  • Functional Blue: #3498db (RGB 52, 152, 219)
  • Warning Yellow: #f1c40f (RGB 241, 196, 15)
  
  DIMENSION COLORS:
  • Overworld: Nature greens and blues
  • Nether: Fiery reds and oranges
  • End: Cosmic purples and blacks
  • Quantum: Superposition blues and pinks
  
  TYPOGRAPHY:
  • Headings: Quantum Sans, Bold
  • Body: Gleam Serif, Regular
  • Code: Monad Mono, Monospace
  
  SPACING SYSTEM:
  • Based on 4px units
  • Small: 4px, Medium: 8px, Large: 16px
  
  ANIMATIONS:
  • Smooth, physics-based movements
  • Functional easing curves
  • Delightful but not distracting
  """)
}


// src/entity.gleam
import gleam/io
import gleam/option.{Option, None, Some}
import gleam/result
import gleam/list
import gleam/map
import gleam/dict
import gleam/float
import gleam/int

// ====================
// Core Entity Types
// ====================

pub type EntityId {
  EntityId(value: Int)
}

pub type EntityType {
  Player(
    username: String,
    game_mode: GameMode,
    permissions: PermissionLevel
  )
  Mob(
    mob_type: MobType,
    variant: MobVariant,
    ai_state: AIState
  )
  Animal(
    animal_type: AnimalType,
    age: Int,
    can_breed: Bool
  )
  ItemEntity(
    item: ItemStack,
    pickup_delay: Int,
    age: Int
  )
  Vehicle(
    vehicle_type: VehicleType,
    passengers: List(EntityId),
    fuel: Float
  )
  Projectile(
    shooter: Option(EntityId),
    projectile_type: ProjectileType,
    velocity: Vector3,
    lifetime: Int
  )
  Structure(
    structure_type: StructureType,
    health: Float,
    owner: Option(EntityId)
  )
  NPC(
    npc_type: NPCType,
    dialog_tree: DialogTree,
    trade_offers: List(TradeOffer)
  )
  Boss(
    boss_type: BossType,
    phase: Int,
    attack_pattern: AttackPattern
  )
  ParticleSystem(
    particle_type: ParticleType,
    emitter_config: EmitterConfig
  )
}

pub type GameMode {
  Survival
  Creative
  Adventure
  Spectator
  Hardcore
}

pub type MobType {
  Zombie
  Skeleton
  Creeper
  Spider
  Enderman
  Witch
  Slime
  // GleamCraft specific
  LambdaLizard
  MonadMoth
  CurryBird
  FoldFox
  MapSlime
}

pub type AnimalType {
  Cow
  Pig
  Sheep
  Chicken
  Wolf
  Cat
  // GleamCraft specific
  PatternPanda
  RecursiveRabbit
  TypeTurtle
}

// ====================
// Entity Components
// ====================

pub type Entity {
  Entity(
    id: EntityId,
    entity_type: EntityType,
    position: Vector3,
    rotation: Vector3,
    velocity: Vector3,
    health: Float,
    max_health: Float,
    armor: Float,
    status_effects: List(StatusEffect),
    inventory: Inventory,
    equipment: Equipment,
    metadata: EntityMetadata,
    physics_body: Option(PhysicsBody),
    render_data: RenderData,
    ai_components: List(AIComponent)
  )
}

pub type EntityMetadata {
  EntityMetadata(
    name_tag: Option(String),
    is_silent: Bool,
    no_gravity: Bool,
    is_glowing: Bool,
    is_invisible: Bool,
    is_on_fire: Bool,
    custom_data: Map(String, Dynamic)
  )
}

pub type PhysicsBody {
  PhysicsBody(
    mass: Float,
    drag: Float,
    angular_drag: Float,
    is_kinematic: Bool,
    constraints: PhysicsConstraints,
    collision_shape: CollisionShape
  )
}

pub type RenderData {
  RenderData(
    model: String,
    texture: String,
    scale: Float,
    tint: Option(RGB),
    animation_state: AnimationState,
    particle_emitters: List(ParticleEmitter)
  )
}

// ====================
// Entity Manager
// ====================

pub type EntityManager {
  EntityManager(
    entities: Dict(EntityId, Entity),
    next_id: Int,
    spatial_index: SpatialIndex,
    entity_by_type: Map(EntityType, List(EntityId)),
    entity_by_chunk: Map(ChunkPosition, List(EntityId))
  )
}

pub fn create_entity_manager() -> EntityManager {
  EntityManager(
    entities: dict.new(),
    next_id: 1,
    spatial_index: create_spatial_index(),
    entity_by_type: map.new(),
    entity_by_chunk: map.new()
  )
}

pub fn spawn_entity(
  manager: EntityManager,
  entity_type: EntityType,
  position: Vector3
) -> #(EntityManager, EntityId) {
  let id = EntityId(manager.next_id)
  
  let entity = create_base_entity(id, entity_type, position)
  
  let updated_entities = dict.insert(manager.entities, id, entity)
  
  // Update spatial index
  let chunk_pos = world_to_chunk(position)
  let chunk_entities = map.get(manager.entity_by_chunk, chunk_pos)
    |> option.unwrap([])
  
  let updated_chunk_map = map.insert(
    manager.entity_by_chunk,
    chunk_pos,
    list.append(chunk_entities, [id])
  )
  
  // Update type index
  let type_entities = map.get(manager.entity_by_type, entity_type)
    |> option.unwrap([])
  
  let updated_type_map = map.insert(
    manager.entity_by_type,
    entity_type,
    list.append(type_entities, [id])
  )
  
  let updated_manager = EntityManager(
    entities: updated_entities,
    next_id: manager.next_id + 1,
    spatial_index: add_to_spatial_index(manager.spatial_index, id, position),
    entity_by_type: updated_type_map,
    entity_by_chunk: updated_chunk_map
  )
  
  #(updated_manager, id)
}

fn create_base_entity(id: EntityId, entity_type: EntityType, position: Vector3) -> Entity {
  let #(health, physics, render) = get_entity_defaults(entity_type)
  
  Entity(
    id: id,
    entity_type: entity_type,
    position: position,
    rotation: {x: 0.0, y: 0.0, z: 0.0},
    velocity: {x: 0.0, y: 0.0, z: 0.0},
    health: health,
    max_health: health,
    armor: 0.0,
    status_effects: [],
    inventory: create_empty_inventory(),
    equipment: empty_equipment(),
    metadata: EntityMetadata(
      name_tag: None,
      is_silent: False,
      no_gravity: False,
      is_glowing: False,
      is_invisible: False,
      is_on_fire: False,
      custom_data: map.new()
    ),
    physics_body: physics,
    render_data: render,
    ai_components: get_default_ai(entity_type)
  )
}

// ====================
// Entity Systems
// ====================

pub type EntitySystem {
  EntitySystem(
    physics_system: PhysicsSystem,
    ai_system: AISystem,
    combat_system: CombatSystem,
    inventory_system: InventorySystem,
    movement_system: MovementSystem,
    interaction_system: InteractionSystem,
    spawn_system: SpawnSystem,
    despawn_system: DespawnSystem
  )
}

pub fn update_entity_system(
  system: EntitySystem,
  manager: EntityManager,
  delta_time: Float
) -> #(EntitySystem, EntityManager) {
  // Update all systems in order
  let #(physics_system, manager1) =
    system.physics_system.update(manager, delta_time)
  
  let #(ai_system, manager2) =
    system.ai_system.update(manager1, delta_time)
  
  let #(movement_system, manager3) =
    system.movement_system.update(manager2, delta_time)
  
  let #(combat_system, manager4) =
    system.combat_system.update(manager3, delta_time)
  
  let #(interaction_system, manager5) =
    system.interaction_system.update(manager4, delta_time)
  
  let #(spawn_system, manager6) =
    system.spawn_system.update(manager5, delta_time)
  
  let #(despawn_system, manager7) =
    system.despawn_system.update(manager6, delta_time)
  
  let updated_system = EntitySystem(
    physics_system: physics_system,
    ai_system: ai_system,
    combat_system: combat_system,
    inventory_system: system.inventory_system,
    movement_system: movement_system,
    interaction_system: interaction_system,
    spawn_system: spawn_system,
    despawn_system: despawn_system
  )
  
  #(updated_system, manager7)
}

// ====================
// Physics System
// ====================

pub type PhysicsSystem {
  PhysicsSystem(
    gravity: Float,
    air_density: Float,
    terminal_velocity: Float,
    collision_layers: Map(String, Bool)
  )
}

pub fn update_physics(system: PhysicsSystem, manager: EntityManager, delta: Float) -> EntityManager {
  dict.fold(
    manager.entities,
    manager,
    fn(id, entity, acc) {
      case entity.physics_body {
        Some(body) ->
          let updated_entity = apply_physics(entity, body, system, delta)
          dict.insert(acc, id, updated_entity)
        
        None -> acc
      }
    }
  )
}

fn apply_physics(entity: Entity, body: PhysicsBody, system: PhysicsSystem, delta: Float) -> Entity {
  // Apply gravity if not disabled
  let velocity = if entity.metadata.no_gravity {
    entity.velocity
  } else {
    let new_y = entity.velocity.y - system.gravity * delta
    {entity.velocity with y: new_y}
  }
  
  // Apply drag
  let drag_factor = 1.0 - (body.drag * delta)
  let velocity = {
    x: velocity.x * drag_factor,
    y: velocity.y * drag_factor,
    z: velocity.z * drag_factor
  }
  
  // Clamp terminal velocity
  let speed_squared = velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z
  let terminal_squared = system.terminal_velocity * system.terminal_velocity
  
  let velocity = if speed_squared > terminal_squared {
    let scale = system.terminal_velocity / float.sqrt(speed_squared)
    {
      x: velocity.x * scale,
      y: velocity.y * scale,
      z: velocity.z * scale
    }
  } else {
    velocity
  }
  
  // Update position
  let position = {
    x: entity.position.x + velocity.x * delta,
    y: entity.position.y + velocity.y * delta,
    z: entity.position.z + velocity.z * delta
  }
  
  Entity(..entity, position: position, velocity: velocity)
}

// ====================
// AI System
// ====================

pub type AISystem {
  AISystem(
    behavior_trees: Map(MobType, BehaviorTree),
    pathfinding: PathfindingSystem,
    sensing: SensingSystem,
    memory: MemorySystem
  )
}

pub type AIState {
  Idle
  Wandering
  Hunting(target: EntityId)
  Fleeing
  Attacking
  Patrolling(path: List(Vector3))
  Following(leader: EntityId)
  Custom(state_name: String, data: Map(String, Dynamic))
}

pub fn update_ai(system: AISystem, manager: EntityManager, delta: Float) -> EntityManager {
  dict.fold(
    manager.entities,
    manager,
    fn(id, entity, acc) {
      case entity.entity_type {
        Mob(mob_type, _, ai_state) ->
          let tree = map.get(system.behavior_trees, mob_type)
            |> option.unwrap(default_behavior_tree())
          
          let new_state = evaluate_behavior_tree(tree, entity, acc, delta)
          let updated_entity = Entity(..entity, ai_state: new_state)
          
          dict.insert(acc, id, updated_entity)
        
        _ -> acc
      }
    }
  )
}

// ====================
// Combat System
// ====================

pub type CombatSystem {
  CombatSystem(
    damage_types: Map(DamageType, DamageModifier),
    hit_registration: HitRegistration,
    knockback_calculator: KnockbackCalculator,
    combat_log: List(CombatEvent)
  )
}

pub fn handle_attack(
  system: CombatSystem,
  attacker: EntityId,
  target: EntityId,
  damage: Float,
  damage_type: DamageType,
  manager: EntityManager
) -> #(CombatSystem, EntityManager, Option(EntityId)) {
  case #(dict.get(manager.entities, attacker), dict.get(manager.entities, target)) {
    #(Some(attacker_entity), Some(target_entity)) ->
      // Calculate modified damage
      let modifier = map.get(system.damage_types, damage_type)
        |> option.unwrap(1.0)
      
      let final_damage = damage * modifier * calculate_crit(attacker_entity)
      
      // Apply damage
      let new_health = target_entity.health - final_damage
      
      let updated_target = if new_health <= 0.0 {
        // Entity died
        Entity(..target_entity, health: 0.0)
      } else {
        Entity(..target_entity, health: new_health)
      }
      
      // Apply knockback
      let knockback = calculate_knockback(
        attacker_entity.position,
        target_entity.position,
        damage_type
      )
      
      let with_knockback = Entity(..updated_target, velocity: {
        x: updated_target.velocity.x + knockback.x,
        y: updated_target.velocity.y + knockback.y,
        z: updated_target.velocity.z + knockback.z
      })
      
      // Update manager
      let updated_entities = dict.insert(manager.entities, target, with_knockback)
      let updated_manager = EntityManager(..manager, entities: updated_entities)
      
      // Log combat event
      let combat_event = CombatEvent(
        attacker: attacker,
        target: target,
        damage: final_damage,
        damage_type: damage_type,
        timestamp: erlang.system_time(millisecond)
      )
      
      let updated_system = CombatSystem(
        ..system,
        combat_log: list.append(system.combat_log, [combat_event])
      )
      
      let died = if new_health <= 0.0 { Some(target) } else { None }
      
      #(updated_system, updated_manager, died)
    
    _ -> #(system, manager, None)
  }
}

// ====================
// Inventory & Equipment
// ====================

pub type Inventory {
  Inventory(
    items: Array(Int, Option(ItemStack)),  // Fixed size array
    selected_slot: Int,
    armor_slots: ArmorSlots,
    offhand: Option(ItemStack)
  )
}

pub type Equipment {
  Equipment(
    main_hand: Option(ItemStack),
    off_hand: Option(ItemStack),
    helmet: Option(ItemStack),
    chestplate: Option(ItemStack),
    leggings: Option(ItemStack),
    boots: Option(ItemStack)
  )
}

pub fn equip_item(entity: Entity, slot: Int, item: ItemStack) -> Result(Entity, String) {
  if slot < 0 || slot >= array.length(entity.inventory.items) {
    Error("Invalid slot")
  } else {
    let updated_items = array.set(entity.inventory.items, slot, Some(item))
    let updated_inventory = Inventory(..entity.inventory, items: updated_items)
    Ok(Entity(..entity, inventory: updated_inventory))
  }
}

// ====================
// Entity Serialization
// ====================

pub fn serialize_entity(entity: Entity) -> EntityData {
  EntityData(
    id: entity.id.value,
    type: entity_type_to_string(entity.entity_type),
    position: entity.position,
    rotation: entity.rotation,
    velocity: entity.velocity,
    health: entity.health,
    metadata: serialize_metadata(entity.metadata),
    inventory: serialize_inventory(entity.inventory),
    ai_state: serialize_ai_state(entity.ai_components)
  )
}

pub fn deserialize_entity(data: EntityData) -> Result(Entity, String) {
  let entity_type = parse_entity_type(data.type)
  let id = EntityId(data.id)
  
  let entity = create_base_entity(id, entity_type, data.position)
  
  let with_rotation = Entity(..entity, rotation: data.rotation)
  let with_velocity = Entity(..with_rotation, velocity: data.velocity)
  let with_health = Entity(..with_velocity, health: data.health)
  
  // Restore inventory
  let inventory = deserialize_inventory(data.inventory)
  let with_inventory = Entity(..with_health, inventory: inventory)
  
  // Restore metadata
  let metadata = deserialize_metadata(data.metadata)
  let with_metadata = Entity(..with_inventory, metadata: metadata)
  
  Ok(with_metadata)
}

// ====================
// Query System
// ====================

pub fn find_entities_in_radius(
  manager: EntityManager,
  center: Vector3,
  radius: Float,
  filter: Option(Entity -> Bool)
) -> List(Entity) {
  let nearby_ids = query_spatial_index(manager.spatial_index, center, radius)
  
  list.filter_map(nearby_ids, fn(id) {
    case dict.get(manager.entities, id) {
      Some(entity) ->
        case filter {
          Some(f) -> if f(entity) { Some(entity) } else { None }
          None -> Some(entity)
        }
      None -> None
    }
  })
}

pub fn find_nearest_entity(
  manager: EntityManager,
  position: Vector3,
  entity_type: EntityType
) -> Option(Entity) {
  let entities_of_type = map.get(manager.entity_by_type, entity_type)
    |> option.unwrap([])
  
  list.fold(
    entities_of_type,
    {distance: infinity, entity: None},
    fn(id, acc) {
      case dict.get(manager.entities, id) {
        Some(entity) ->
          let distance = vector.distance(position, entity.position)
          if distance < acc.distance {
            {distance: distance, entity: Some(entity)}
          } else {
            acc
          }
        None -> acc
      }
    }
  ).entity
}

// ====================
// Event System
// ====================

pub type EntityEvent {
  EntitySpawned(entity: Entity)
  EntityDespawned(entity_id: EntityId, reason: DespawnReason)
  EntityDamaged(
    entity_id: EntityId,
    damage: Float,
    damage_type: DamageType,
    source: Option(EntityId)
  )
  EntityHealed(entity_id: EntityId, amount: Float, source: Option(EntityId))
  EntityMoved(entity_id: EntityId, from: Vector3, to: Vector3)
  EntityInteracted(
    entity_id: EntityId,
    target: EntityId,
    interaction_type: InteractionType
  )
  InventoryChanged(entity_id: EntityId, slot: Int, old_item: Option(ItemStack), new_item: Option(ItemStack))
  EquipmentChanged(entity_id: EntityId, slot: EquipmentSlot, item: Option(ItemStack))
}

pub type EventBus {
  EventBus(
    subscribers: Map(EntityEventType, List(EventCallback)),
    event_queue: List(EntityEvent),
    max_history: Int,
    event_history: List(EntityEvent)
  )
}

pub fn emit_event(bus: EventBus, event: EntityEvent) -> EventBus {
  let updated_queue = list.append(bus.event_queue, [event])
  
  // Notify subscribers
  let event_type = get_event_type(event)
  case map.get(bus.subscribers, event_type) {
    Some(callbacks) ->
      list.each(callbacks, fn(callback) { callback(event) })
    
    None -> Nil
  }
  
  EventBus(..bus, event_queue: updated_queue)
}

// ====================
// Entity Factory
// ====================

pub fn create_player(username: String, position: Vector3) -> Entity {
  let id = EntityId(0)  // Temporary, will be assigned by manager
  let entity_type = Player(
    username: username,
    game_mode: Survival,
    permissions: PlayerPermissions
  )
  
  create_base_entity(id, entity_type, position)
  |> set_player_defaults(username)
}

pub fn create_mob(mob_type: MobType, position: Vector3, variant: MobVariant) -> Entity {
  let id = EntityId(0)
  let entity_type = Mob(
    mob_type: mob_type,
    variant: variant,
    ai_state: Idle
  )
  
  create_base_entity(id, entity_type, position)
  |> set_mob_defaults(mob_type, variant)
}

pub fn create_item_entity(item: ItemStack, position: Vector3) -> Entity {
  let id = EntityId(0)
  let entity_type = ItemEntity(
    item: item,
    pickup_delay: 40,  // 2 seconds at 20 TPS
    age: 0
  )
  
  create_base_entity(id, entity_type, position)
  |> set_item_entity_defaults()
}