extends Node2D
class_name BaseLevel

@export var p1_type: String = "Square"
@export var p2_type: String = "Circle"

@onready var p1_spawn_marker: Marker2D = $P1Spawn
@onready var p2_spawn_marker: Marker2D = $P2Spawn

var player1: BasePlayer = null
var player2: BasePlayer = null

@onready var overlap_highlight: Polygon2D = get_node_or_null("OverlapHighlight")
@onready var overlap_outline: Line2D = get_node_or_null("OverlapHighlight/Outline")

func _ready() -> void:
	# Spawnăm jucătorii
	spawn_players()

	# Înregistrăm nivelul în GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.level_changed.emit(scene_file_path)

func _process(_delta: float) -> void:
	if not player1 or not player2 or not overlap_highlight:
		return

	# Obținem poligoanele globale ale ambilor jucători
	var p1_global = player1.to_global_points(player1.polygon, player1.global_transform)
	var p2_global = player2.to_global_points(player2.polygon, player2.global_transform)

	# Calculăm intersecția/suprapunerea lor în spațiul global (scena este la 0,0, deci este egal cu spațiul global)
	var intersections = Geometry2D.intersect_polygons(p1_global, p2_global)
	if intersections.size() > 0:
		var poly = intersections[0]
		overlap_highlight.polygon = poly

		# Setăm punctele conturului și închidem bucla
		var pts = Array(poly)
		if pts.size() > 0:
			pts.append(pts[0])
		if overlap_outline:
			overlap_outline.points = PackedVector2Array(pts)
	else:
		overlap_highlight.polygon = PackedVector2Array()
		if overlap_outline:
			overlap_outline.points = PackedVector2Array()

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
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play:
		# Host controlează Player1, Client controlează Player2
		player1.set_multiplayer_authority(1) # Host-ul este mereu 1

		if multiplayer.is_server():
			# Pe Host, Player 2 aparține primului client conectat
			var peers = multiplayer.get_peers()
			if peers.size() > 0:
				player2.set_multiplayer_authority(peers[0])
			else:
				player2.set_multiplayer_authority(1) # fallback
		else:
			# Pe Client, Player 2 aparține propriei instanțe a clientului
			player2.set_multiplayer_authority(multiplayer.get_unique_id())

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
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play:
		if multiplayer.is_server():
			rpc("complete_level_rpc")
	else:
		# Local Co-op
		show_completion_on_hud()

@rpc("any_peer", "call_local", "reliable")
func complete_level_rpc() -> void:
	show_completion_on_hud()

func show_completion_on_hud() -> void:
	var hud = get_node_or_null("HUD")
	if hud:
		hud.show_level_completed()
	else:
		# fallback dacă nu există HUD
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.unlock_next_level()
			game_manager.next_level()
