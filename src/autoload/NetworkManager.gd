extends Node

signal peer_connected_custom(id: int)
signal peer_disconnected_custom(id: int)
signal connection_failed_custom()
signal connection_succeeded_custom()
signal server_disconnected_custom()

signal lan_servers_updated(servers: Array)

const PORT = 8910
const BROADCAST_PORT = 8911
const BROADCAST_INTERVAL = 1.0

var peer: ENetMultiplayerPeer = null
var udp_broadcaster: PacketPeerUDP = null
var udp_listener: PacketPeerUDP = null

var detected_servers = {} # IP -> {name, time}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
	# Ascultăm pachetele UDP pentru descoperirea serverelor LAN
	if udp_listener and udp_listener.is_bound():
		while udp_listener.get_available_packet_count() > 0:
			var packet = udp_listener.get_packet()
			var ip = udp_listener.get_packet_ip()
			var msg = packet.get_string_from_utf8()
			if msg.begins_with("SnipItHost:"):
				var server_name = msg.trim_prefix("SnipItHost:")
				detected_servers[ip] = {
					"name": server_name,
					"ip": ip,
					"last_seen": Time.get_ticks_msec()
				}
				_clean_and_emit_servers()

func is_multiplayer_active() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

# --- Creare Host ---
func create_host(host_name: String) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, 2) # max 2 jucători (P1 + P2)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer

	# Pornim serverul de broadcast UDP
	start_udp_broadcast(host_name)
	return OK

# --- Alăturare Client ---
func join_host(ip: String) -> Error:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

# --- Deconectare ---
func disconnect_network() -> void:
	stop_udp_broadcast()
	stop_udp_listener()
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null

# --- UDP Discovery ---
func start_udp_broadcast(host_name: String) -> void:
	stop_udp_broadcast()
	udp_broadcaster = PacketPeerUDP.new()
	udp_broadcaster.set_dest_address("255.255.255.255", BROADCAST_PORT)

	# Trimitem pachete de broadcast la fiecare secundă
	var timer = Timer.new()
	timer.name = "UDPBroadcastTimer"
	timer.wait_time = BROADCAST_INTERVAL
	timer.autostart = true
	timer.timeout.connect(func():
		if udp_broadcaster:
			var packet_data = ("SnipItHost:" + host_name).to_utf8_buffer()
			udp_broadcaster.put_packet(packet_data)
	)
	add_child(timer)

func stop_udp_broadcast() -> void:
	if has_node("UDPBroadcastTimer"):
		get_node("UDPBroadcastTimer").queue_free()
	if udp_broadcaster:
		udp_broadcaster.close()
		udp_broadcaster = null

func start_udp_listener() -> void:
	stop_udp_listener()
	udp_listener = PacketPeerUDP.new()
	var err = udp_listener.bind(BROADCAST_PORT)
	if err != OK:
		push_error("Nu s-a putut asculta portul UDP de broadcast")

func stop_udp_listener() -> void:
	detected_servers.clear()
	if udp_listener:
		udp_listener.close()
		udp_listener = null

func _clean_and_emit_servers() -> void:
	var now = Time.get_ticks_msec()
	var list = []
	for ip in detected_servers.keys():
		# Eliminăm serverele care nu au mai trimis semnal de mai mult de 4 secunde
		if now - detected_servers[ip]["last_seen"] > 4000:
			detected_servers.erase(ip)
		else:
			list.append(detected_servers[ip])
	lan_servers_updated.emit(list)

# --- Callbacks Multiplayer ---
func _on_peer_connected(id: int) -> void:
	peer_connected_custom.emit(id)

func _on_peer_disconnected(id: int) -> void:
	peer_disconnected_custom.emit(id)

func _on_connected_to_server() -> void:
	connection_succeeded_custom.emit()

func _on_connection_failed() -> void:
	connection_failed_custom.emit()

func _on_server_disconnected() -> void:
	server_disconnected_custom.emit()

# --- RPC Sincronizare Co-op IAP ---
@rpc("any_peer", "call_local", "reliable")
func sync_remove_ads_status(status: bool) -> void:
	GameManager.remove_ads_purchased = status
	AdManager.remove_ads_status_changed.emit()
