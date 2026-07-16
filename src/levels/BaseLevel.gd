extends Node2D
class_name BaseLevel

@export var p1_type: String = "Square"
@export var p2_type: String = "Circle"

@onready var p1_spawn_marker: Marker2D = $P1Spawn
@onready var p2_spawn_marker: Marker2D = $P2Spawn

var player1: BasePlayer = null
var player2: BasePlayer = null

func _ready() -> void:
	# Spawnăm jucătorii
	spawn_players()

	# Înregistrăm nivelul în GameManager
	GameManager.level_changed.emit(scene_file_path)

func spawn_players() -> void:
	var player_scene = load("res://src/players/BasePlayer.tscn")

	# --- Jucătorul 1 ---
	player1 = player_scene.instantiate() as BasePlayer
	var script_p1 = get_player_script(p1_type)
	player1.set_script(script_p1)
	player1.player_id = 1
	player1.global_position = p1_spawn_marker.global_position
	player1.name = "Player1"
	add_child(player1)

	# --- Jucătorul 2 ---
	player2 = player_scene.instantiate() as BasePlayer
	var script_p2 = get_player_script(p2_type)
	player2.set_script(script_p2)
	player2.player_id = 2
	player2.global_position = p2_spawn_marker.global_position
	player2.name = "Player2"
	add_child(player2)

	# Setează autoritatea de rețea în caz de LAN
	if GameManager.is_lan_play:
		# Host controlează Player1, Client controlează Player2
		player1.set_multiplayer_authority(1) # Host-ul este mereu 1

		# Găsim id-ul peer-ului conectat (Clientul)
		var peers = multiplayer.get_peers()
		if peers.size() > 0:
			player2.set_multiplayer_authority(peers[0])
		else:
			player2.set_multiplayer_authority(1) # fallback

func get_player_script(type: String) -> Script:
	match type:
		"Square":
			return load("res://src/players/SquarePlayer.gd")
		"Circle":
			return load("res://src/players/CirclePlayer.gd")
		"Capsule":
			return load("res://src/players/CapsulePlayer.gd")
		"Diamond":
			return load("res://src/players/DiamondPlayer.gd")
	return load("res://src/players/SquarePlayer.gd")

func complete_level() -> void:
	# Avansează la următorul nivel
	if GameManager.is_lan_play:
		if multiplayer.is_server():
			rpc("complete_level_rpc")
	else:
		GameManager.next_level()

@rpc("any_peer", "call_local", "reliable")
func complete_level_rpc() -> void:
	GameManager.next_level()
