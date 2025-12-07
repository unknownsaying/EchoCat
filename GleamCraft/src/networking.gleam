// src/network.gleam
import gleam/io
import gleam/option.{Option, None, Some}
import gleam/result
import gleam/list
import gleam/map
import gleam/dict
import gleam/erlang.{process, receive}
import gleam/bit_string
import gleam/int
import gleam/float

// ====================
// Network Architecture
// ====================

pub type NetworkMode {
  Server
  Client
  PeerToPeer
  Hybrid
}

pub type NetworkConfig {
  NetworkConfig(
    mode: NetworkMode,
    port: Int,
    max_connections: Int,
    compression_threshold: Int,
    encryption_enabled: Bool,
    protocol_version: String,
    timeout_ms: Int,
    packet_loss_simulation: Float,  // For testing
    bandwidth_limit: Option(Int)    // Bytes per second
  )
}

pub const default_server_config = NetworkConfig(
  mode: Server,
  port: 25565,
  max_connections: 20,
  compression_threshold: 1024,
  encryption_enabled: True,
  protocol_version: "GCW-1.0",
  timeout_ms: 30000,
  packet_loss_simulation: 0.0,
  bandwidth_limit: None
)

pub const default_client_config = NetworkConfig(
  mode: Client,
  port: 0,  // Ephemeral
  max_connections: 1,
  compression_threshold: 1024,
  encryption_enabled: True,
  protocol_version: "GCW-1.0",
  timeout_ms: 5000,
  packet_loss_simulation: 0.0,
  bandwidth_limit: None
)

// ====================
// Connection Management
// ====================

pub type ConnectionId {
  ConnectionId(value: Int)
}

pub type ConnectionState {
  Handshaking
  Status
  Login
  Play
  Disconnected
}

pub type Connection {
  Connection(
    id: ConnectionId,
    socket: Socket,
    state: ConnectionState,
    player_id: Option(EntityId),
    username: Option(String),
    address: String,
    port: Int,
    compression_threshold: Int,
    encryption_key: Option(EncryptionKey),
    last_ping: Int,
    packets_sent: Int,
    packets_received: Int,
    bandwidth_usage: BandwidthStats,
    latency: Int,  // ms
    connection_time: Int
  )
}

pub type ConnectionManager {
  ConnectionManager(
    connections: Dict(ConnectionId, Connection),
    next_connection_id: Int,
    player_to_connection: Map(EntityId, ConnectionId),
    username_to_connection: Map(String, ConnectionId),
    address_blacklist: List(String),
    connection_limit_per_ip: Int
  )
}

pub fn create_connection_manager() -> ConnectionManager {
  ConnectionManager(
    connections: dict.new(),
    next_connection_id: 1,
    player_to_connection: map.new(),
    username_to_connection: map.new(),
    address_blacklist: [],
    connection_limit_per_ip: 3
  )
}

pub fn accept_connection(
  manager: ConnectionManager,
  socket: Socket,
  address: String,
  port: Int
) -> #(ConnectionManager, ConnectionId) {
  let id = ConnectionId(manager.next_connection_id)
  
  // Check blacklist
  if list.contains(manager.address_blacklist, address) {
    // Reject connection
    socket.close()
    #(manager, id)
  } else {
    // Check connection limit for IP
    let connections_from_ip = count_connections_from_ip(manager, address)
    
    if connections_from_ip >= manager.connection_limit_per_ip {
      socket.close()
      #(manager, id)
    } else {
      let connection = Connection(
        id: id,
        socket: socket,
        state: Handshaking,
        player_id: None,
        username: None,
        address: address,
        port: port,
        compression_threshold: -1,  // No compression initially
        encryption_key: None,
        last_ping: erlang.system_time(millisecond),
        packets_sent: 0,
        packets_received: 0,
        bandwidth_usage: BandwidthStats(0, 0, 0, 0),
        latency: 0,
        connection_time: erlang.system_time(millisecond)
      )
      
      let updated_connections = dict.insert(manager.connections, id, connection)
      
      let updated_manager = ConnectionManager(
        connections: updated_connections,
        next_connection_id: manager.next_connection_id + 1,
        player_to_connection: manager.player_to_connection,
        username_to_connection: manager.username_to_connection,
        address_blacklist: manager.address_blacklist,
        connection_limit_per_ip: manager.connection_limit_per_ip
      )
      
      #(updated_manager, id)
    }
  }
}

// ====================
// Packet System
// ====================

pub type PacketId {
  Handshake
  StatusRequest
  StatusResponse
  LoginStart
  LoginSuccess
  LoginDisconnect
  KeepAlive
  PlayerPosition
  PlayerLook
  PlayerPositionLook
  ChunkData
  BlockChange
  EntitySpawn
  EntityMove
  EntityTeleport
  EntityDestroy
  ChatMessage
  Disconnect
  // Game-specific
  GleamFunctionCall
  TypeAssertion
  PatternMatchResult
}

pub type Packet {
  Packet(
    id: PacketId,
    data: BitString,
    reliable: Bool,
    priority: PacketPriority,
    timestamp: Int,
    sequence_number: Option(Int)
  )
}

pub type PacketPriority {
  Critical  // Player input, essential updates
  High      // Entity movements, chunk updates
  Medium    // Chat, inventory updates
  Low       // Particle effects, ambient sounds
  Bulk      // World generation, large data
}

pub type PacketHandler {
  PacketHandler(
    handlers: Map(PacketId, PacketCallback),
    middleware: List(PacketMiddleware),
    packet_pool: PacketPool,
    statistics: PacketStats
  )
}

pub fn register_packet_handler(
  handler: PacketHandler,
  packet_id: PacketId,
  callback: PacketCallback
) -> PacketHandler {
  let updated_handlers = map.insert(handler.handlers, packet_id, callback)
  PacketHandler(..handler, handlers: updated_handlers)
}

pub fn handle_packet(
  handler: PacketHandler,
  connection_id: ConnectionId,
  packet: Packet,
  manager: ConnectionManager
) -> #(PacketHandler, ConnectionManager) {
  // Apply middleware
  let #(processed_packet, updated_manager) = apply_middleware(
    handler.middleware,
    connection_id,
    packet,
    manager
  )
  
  // Find handler
  case map.get(handler.handlers, processed_packet.id) {
    Some(callback) ->
      let #(new_manager, response) = callback(connection_id, processed_packet, updated_manager)
      
      // Update statistics
      let stats = update_packet_stats(handler.statistics, processed_packet.id, 1)
      let updated_handler = PacketHandler(..handler, statistics: stats)
      
      // Send response if any
      case response {
        Some(response_packet) ->
          send_packet(new_manager, connection_id, response_packet)
          #(updated_handler, new_manager)
        
        None -> #(updated_handler, new_manager)
      }
    
    None ->
      // No handler for this packet
      io.debug("No handler for packet", processed_packet.id)
      #(handler, updated_manager)
  }
}

// ====================
// Protocol Implementation
// ====================

pub type GleamCraftProtocol {
  GleamCraftProtocol(
    version: String,
    packet_format: PacketFormat,
    compression: CompressionAlgorithm,
    encryption: EncryptionScheme,
    state_machine: ProtocolStateMachine
  )
}

pub const protocol = GleamCraftProtocol(
  version: "GCW-1.0",
  packet_format: VarIntLengthPrefixed,
  compression: Zlib(level: 3),
  encryption: AES256_GCM,
  state_machine: create_protocol_state_machine()
)

pub fn encode_packet(packet: Packet) -> Result(BitString, String> {
  // Encode based on protocol
  let header = encode_packet_header(packet.id, packet.reliable, packet.priority)
  let encoded_data = encode_packet_data(packet.id, packet.data)
  
  case protocol.compression {
    Zlib(level) ->
      if bit_string.byte_size(encoded_data) > protocol.compression_threshold {
        let compressed = compress(encoded_data, level)
        Ok(bit_string.concat([header, compressed]))
      } else {
        let length = bit_string.byte_size(encoded_data)
        let length_prefix = encode_varint(length)
        Ok(bit_string.concat([header, length_prefix, encoded_data]))
      }
    
    None ->
      Ok(bit_string.concat([header, encoded_data]))
  }
}

pub fn decode_packet(data: BitString) -> Result(Packet, String> {
  // Decode header
  let #(packet_id, reliable, priority, remaining) = decode_packet_header(data)
  
  // Handle compression
  let packet_data = case protocol.compression {
    Zlib(_) ->
      let #(data_length, compressed_data) = decode_varint(remaining)
      if data_length == 0 {
        // Uncompressed
        compressed_data
      } else {
        decompress(compressed_data, data_length)
      }
    
    None -> remaining
  }
  
  let decoded_data = decode_packet_data(packet_id, packet_data)
  
  Ok(Packet(
    id: packet_id,
    data: decoded_data,
    reliable: reliable,
    priority: priority,
    timestamp: erlang.system_time(millisecond),
    sequence_number: None
  ))
}

// ====================
// Server Implementation
// ====================

pub type GameServer {
  GameServer(
    config: NetworkConfig,
    connection_manager: ConnectionManager,
    packet_handler: PacketHandler,
    world_sync: WorldSyncSystem,
    player_manager: PlayerManager,
    event_bus: EventBus,
    tick_rate: Int,  // Ticks per second
    is_running: Bool,
    performance_stats: ServerStats
  )
}

pub fn start_server(config: NetworkConfig) -> Result(process.Pid, String) {
  // Create server socket
  case create_server_socket(config.port) {
    Ok(socket) ->
      let server = GameServer(
        config: config,
        connection_manager: create_connection_manager(),
        packet_handler: create_default_packet_handler(),
        world_sync: create_world_sync_system(),
        player_manager: create_player_manager(),
        event_bus: create_event_bus(),
        tick_rate: 20,
        is_running: True,
        performance_stats: initial_server_stats()
      )
      
      let pid = process.spawn(fn() -> server_loop(server, socket))
      Ok(pid)
    
    Error(msg) -> Error("Failed to create server socket: " <> msg)
  }
}

fn server_loop(server: GameServer, socket: Socket) -> Nil {
  if not server.is_running {
    // Cleanup
    socket.close()
    Nil
  } else {
    // Accept new connections
    case socket.accept(100) {  // 100ms timeout
      Ok(#(client_socket, address, port)) ->
        let #(manager, connection_id) = accept_connection(
          server.connection_manager,
          client_socket,
          address,
          port
        )
        
        let updated_server = GameServer(..server, connection_manager: manager)
        server_loop(updated_server, socket)
      
      Error(_) -> 
        // Process existing connections
        let updated_server = process_connections(server)
        server_loop(updated_server, socket)
    }
  }
}

fn process_connections(server: GameServer) -> GameServer {
  // Process packets from all connections
  let updated_manager = dict.fold(
    server.connection_manager.connections,
    server.connection_manager,
    fn(connection_id, connection, acc_manager) {
      case connection.socket.receive(0) {  // Non-blocking
        Ok(packet_data) ->
          case decode_packet(packet_data) {
            Ok(packet) ->
              let #(handler, new_manager) = handle_packet(
                server.packet_handler,
                connection_id,
                packet,
                acc_manager
              )
              
              let updated_server = GameServer(..server, 
                connection_manager: new_manager,
                packet_handler: handler
              )
              
              process_connections(updated_server)
            
            Error(msg) ->
              io.debug("Failed to decode packet", msg)
              acc_manager
          }
        
        Error(_) -> acc_manager
      }
    }
  )
  
  GameServer(..server, connection_manager: updated_manager)
}

// ====================
// Client Implementation
// ====================

pub type GameClient {
  GameClient(
    config: NetworkConfig,
    connection: Option(Connection>,
    packet_handler: PacketHandler,
    server_info: Option(ServerInfo),
    player_data: PlayerData,
    connection_state: ConnectionState,
    outgoing_queue: List(Packet),
    incoming_queue: List(Packet),
    reconnect_attempts: Int,
    latency: Int,
    bandwidth_stats: BandwidthStats
  )
}

pub fn connect_to_server(
  client: GameClient,
  address: String,
  port: Int
) -> Result(GameClient, String) {
  case create_client_socket(address, port) {
    Ok(socket) ->
      let connection = Connection(
        id: ConnectionId(0),  // Client-side ID
        socket: socket,
        state: Handshaking,
        player_id: None,
        username: client.player_data.username,
        address: address,
        port: port,
        compression_threshold: -1,
        encryption_key: None,
        last_ping: erlang.system_time(millisecond),
        packets_sent: 0,
        packets_received: 0,
        bandwidth_usage: BandwidthStats(0, 0, 0, 0),
        latency: 0,
        connection_time: erlang.system_time(millisecond)
      )
      
      // Send handshake
      let handshake = create_handshake_packet(
        protocol.version,
        address,
        port,
        NextState.Login
      )
      
      case send_packet_direct(connection, handshake) {
        Ok(updated_connection) ->
          let updated_client = GameClient(
            ..client,
            connection: Some(updated_connection),
            connection_state: Handshaking
          )
          Ok(updated_client)
        
        Error(msg) -> Error("Failed to send handshake: " <> msg)
      }
    
    Error(msg) -> Error("Failed to connect: " <> msg)
  }
}

pub fn client_update_loop(client: GameClient) -> GameClient {
  case client.connection {
    Some(connection) ->
      // Send queued packets
      let #(updated_connection, remaining_outgoing) = send_queued_packets(
        connection,
        client.outgoing_queue
      )
      
      // Receive packets
      case connection.socket.receive(0) {
        Ok(packet_data) ->
          case decode_packet(packet_data) {
            Ok(packet) ->
              let #(handler, updated_client) = handle_client_packet(
                client.packet_handler,
                packet,
                client
              )
              
              let with_queue = GameClient(..updated_client,
                outgoing_queue: remaining_outgoing,
                incoming_queue: list.append(updated_client.incoming_queue, [packet])
              )
              
              client_update_loop(with_queue)
            
            Error(_) -> client_update_loop(client)
          }
        
        Error(_) ->
          // Check connection health
          let time_since_ping = erlang.system_time(millisecond) - connection.last_ping
          if time_since_ping > 15000 {  // 15 seconds
            // Timeout, try to reconnect
            attempt_reconnect(client)
          } else {
            GameClient(..client,
              connection: Some(updated_connection),
              outgoing_queue: remaining_outgoing
            )
          }
      }
    
    None -> client  // Not connected
  }
}

// ====================
// World Synchronization
// ====================

pub type WorldSyncSystem {
  WorldSyncSystem(
    chunk_sync: ChunkSyncManager,
    entity_sync: EntitySyncManager,
    block_sync: BlockSyncManager,
    view_distance_manager: ViewDistanceManager,
    interpolation: InterpolationSystem
  )
}

pub fn sync_chunk_to_player(
  sync: WorldSyncSystem,
  player_id: EntityId,
  chunk_pos: ChunkPosition,
  world: World,
  connection: Connection
) -> Connection {
  let chunk_data = get_chunk_data(world, chunk_pos)
  let packet = create_chunk_data_packet(chunk_pos, chunk_data)
  
  send_packet_direct(connection, packet)
  |> result.unwrap(connection)
}

pub fn sync_entity_to_player(
  sync: WorldSyncSystem,
  player_id: EntityId,
  entity: Entity,
  connection: Connection
) -> Connection {
  let packet = create_entity_spawn_packet(entity)
  
  send_packet_direct(connection, packet)
  |> result.unwrap(connection)
}

// ====================
// Reliable UDP Layer
// ====================

pub type ReliableUDP {
  ReliableUDP(
    sequence_number: Int,
    acknowledged_packets: Set(Int),
    pending_packets: Dict(Int, {packet: Packet, sent_time: Int, retries: Int}),
    max_retries: Int,
    rtt: Int,  // Round trip time
    jitter: Int,
    packet_loss: Float,
    congestion_window: Int
  )
}

pub fn send_reliable_packet(
  rudp: ReliableUDP,
  connection: Connection,
  packet: Packet
) -> #(ReliableUDP, Connection) {
  let sequence = rudp.sequence_number
  let packet_with_seq = Packet(..packet, sequence_number: Some(sequence))
  
  let encoded = encode_packet(packet_with_seq)
    |> result.unwrap
  
  let sent_time = erlang.system_time(millisecond)
  
  let pending = dict.insert(
    rudp.pending_packets,
    sequence,
    {packet: packet_with_seq, sent_time: sent_time, retries: 0}
  )
  
  let updated_rudp = ReliableUDP(
    sequence_number: sequence + 1,
    acknowledged_packets: rudp.acknowledged_packets,
    pending_packets: pending,
    max_retries: rudp.max_retries,
    rtt: rudp.rtt,
    jitter: rudp.jitter,
    packet_loss: rudp.packet_loss,
    congestion_window: rudp.congestion_window
  )
  
  case connection.socket.send(encoded) {
    Ok(socket) ->
      let updated_connection = Connection(..connection, socket: socket)
      #(updated_rudp, updated_connection)
    
    Error(_) -> #(rudp, connection)  // Will retry
  }
}

pub fn process_acknowledgement(
  rudp: ReliableUDP,
  ack_sequence: Int
) -> ReliableUDP {
  // Mark packet as acknowledged
  let updated_acks = set.insert(rudp.acknowledged_packets, ack_sequence)
  let updated_pending = dict.delete(rudp.pending_packets, ack_sequence)
  
  // Update RTT based on packet send time
  case dict.get(rudp.pending_packets, ack_sequence) {
    Some({sent_time: sent_time, ..}) ->
      let rtt = erlang.system_time(millisecond) - sent_time
      let new_rtt = (rudp.rtt * 7 + rtt) / 8  // Exponential moving average
      
      ReliableUDP(..rudp,
        acknowledged_packets: updated_acks,
        pending_packets: updated_pending,
        rtt: new_rtt
      )
    
    None -> ReliableUDP(..rudp,
      acknowledged_packets: updated_acks,
      pending_packets: updated_pending
    )
  }
}

// ====================
// Security & Encryption
// ====================

pub type SecuritySystem {
  SecuritySystem(
    encryption: EncryptionManager,
    authentication: AuthManager,
    rate_limiter: RateLimiter,
    packet_validator: PacketValidator,
    ban_manager: BanManager
  )
}

pub fn encrypt_packet(
  security: SecuritySystem,
  packet: Packet,
  key: EncryptionKey
) -> Result(Packet, String> {
  let encrypted_data = security.encryption.encrypt(packet.data, key)
  Ok(Packet(..packet, data: encrypted_data))
}

pub fn verify_packet_integrity(
  security: SecuritySystem,
  packet: Packet,
  connection: Connection
) -> Bool {
  // Check rate limiting
  if not security.rate_limiter.allow_packet(connection.address, packet.id) {
    False
  } else {
    // Validate packet structure
    security.packet_validator.validate(packet)
  }
}

// ====================
// Bandwidth Management
// ====================

pub type BandwidthManager {
  BandwidthManager(
    limits: BandwidthLimits,
    usage: BandwidthUsage,
    throttling: ThrottlingConfig,
    compression_estimator: CompressionEstimator,
    packet_prioritizer: PacketPrioritizer
  )
}

pub type BandwidthLimits {
  BandwidthLimits(
    upload_limit: Option(Int),  // bytes/sec
    download_limit: Option(Int),
    per_packet_limit: Option(Int),
    burst_limit: Option(Int)
  )
}

pub fn manage_bandwidth(
  manager: BandwidthManager,
  packet: Packet,
  connection: Connection
) -> Result(Packet, String> {
  let packet_size = bit_string.byte_size(packet.data)
  
  // Check per-packet limit
  case manager.limits.per_packet_limit {
    Some(limit) if packet_size > limit ->
      Error("Packet too large")
    
    _ ->
      // Check overall usage
      let current_usage = manager.usage.current_upload
      let limit = manager.limits.upload_limit |> option.unwrap(1000000)  // 1MB default
      
      if current_usage + packet_size > limit {
        // Apply throttling
        case packet.priority {
          Critical -> Ok(packet)  // Allow critical packets
          _ -> Error("Bandwidth limit exceeded")
        }
      } else {
        // Consider compression
        if should_compress(manager.compression_estimator, packet) {
          let compressed = compress_packet(packet)
          Ok(compressed)
        } else {
          Ok(packet)
        }
      }
  }
}

// ====================
// NAT Traversal & P2P
// ====================

pub type P2PNetwork {
  P2PNetwork(
    peers: Map(PeerId, PeerInfo),
    stun_servers: List(StunServer),
    turn_servers: List(TurnServer),
    hole_punching: HolePunchingSystem,
    peer_discovery: PeerDiscovery,
    relay_enabled: Bool
  )
}

pub fn establish_p2p_connection(
  p2p: P2PNetwork,
  target_peer: PeerId
) -> Result(Connection, String> {
  // Try direct connection first
  case attempt_direct_connection(p2p, target_peer) {
    Ok(connection) -> Ok(connection)
    
    Error(_) ->
      // Try hole punching
      case p2p.hole_punching.punch(target_peer) {
        Ok(connection) -> Ok(connection)
        
        Error(_) ->
          // Fall back to relay
          if p2p.relay_enabled {
            establish_relayed_connection(p2p, target_peer)
          } else {
            Error("Failed to establish P2P connection")
          }
      }
  }
}

// ====================
// Network Statistics
// ====================

pub type NetworkStatistics {
  NetworkStatistics(
    total_packets_sent: Int,
    total_packets_received: Int,
    total_bytes_sent: Int,
    total_bytes_received: Int,
    average_latency: Float,
    packet_loss_rate: Float,
    connection_count: Int,
    peak_bandwidth: Float,
    uptime: Int,
    errors: List(NetworkError>
  )
}

pub fn collect_statistics(server: GameServer) -> NetworkStatistics {
  let connections = dict.to_list(server.connection_manager.connections)
  
  let stats = list.fold(connections, initial_stats(), fn(_, connection, acc) {
    NetworkStatistics(
      total_packets_sent: acc.total_packets_sent + connection.packets_sent,
      total_packets_received: acc.total_packets_received + connection.packets_received,
      total_bytes_sent: acc.total_bytes_sent + connection.bandwidth_usage.bytes_sent,
      total_bytes_received: acc.total_bytes_received + connection.bandwidth_usage.bytes_received,
      average_latency: (acc.average_latency + float.from_int(connection.latency)) / 2.0,
      packet_loss_rate: acc.packet_loss_rate,
      connection_count: acc.connection_count + 1,
      peak_bandwidth: float.max(acc.peak_bandwidth, calculate_bandwidth(connection)),
      uptime: acc.uptime,
      errors: acc.errors
    )
  })
  
  NetworkStatistics(..stats, uptime: erlang.system_time(millisecond) - server.start_time)
}

// ====================
// Main Network Manager
// ====================

pub type NetworkManager {
  NetworkManager(
    config: NetworkConfig,
    server: Option(GameServer),
    client: Option(GameClient),
    p2p: Option(P2PNetwork),
    statistics: NetworkStatistics,
    event_handler: EventHandler,
    is_initialized: Bool
  )
}

pub fn initialize_network(config: NetworkConfig) -> NetworkManager {
  case config.mode {
    Server ->
      let server = start_server(config)
        |> result.unwrap
      
      NetworkManager(
        config: config,
        server: Some(server),
        client: None,
        p2p: None,
        statistics: empty_statistics(),
        event_handler: create_default_event_handler(),
        is_initialized: True
      )
    
    Client ->
      let client = GameClient(
        config: config,
        connection: None,
        packet_handler: create_default_packet_handler(),
        server_info: None,
        player_data: default_player_data(),
        connection_state: Disconnected,
        outgoing_queue: [],
        incoming_queue: [],
        reconnect_attempts: 0,
        latency: 0,
        bandwidth_stats: empty_bandwidth_stats()
      )
      
      NetworkManager(
        config: config,
        server: None,
        client: Some(client),
        p2p: None,
        statistics: empty_statistics(),
        event_handler: create_default_event_handler(),
        is_initialized: True
      )
    
    PeerToPeer ->
      let p2p = P2PNetwork(
        peers: map.new(),
        stun_servers: default_stun_servers(),
        turn_servers: [],
        hole_punching: create_hole_punching_system(),
        peer_discovery: create_peer_discovery(),
        relay_enabled: False
      )
      
      NetworkManager(
        config: config,
        server: None,
        client: None,
        p2p: Some(p2p),
        statistics: empty_statistics(),
        event_handler: create_default_event_handler(),
        is_initialized: True
      )
    
    Hybrid ->
      // Both server and client
      let server = start_server(config)
        |> result.unwrap
      
      let client = GameClient(
        config: config,
        connection: None,
        packet_handler: create_default_packet_handler(),
        server_info: None,
        player_data: default_player_data(),
        connection_state: Disconnected,
        outgoing_queue: [],
        incoming_queue: [],
        reconnect_attempts: 0,
        latency: 0,
        bandwidth_stats: empty_bandwidth_stats()
      )
      
      NetworkManager(
        config: config,
        server: Some(server),
        client: Some(client),
        p2p: None,
        statistics: empty_statistics(),
        event_handler: create_default_event_handler(),
        is_initialized: True
      )
  }
}