extends Node

signal level_changed(level_path: String)
signal player_colors_updated()

# Culori selectate de jucători (implicit Albastru pentru P1, Roșu pentru P2)
var p1_color: Color = Color("0088ff") # Blue
var p2_color: Color = Color("ff3344") # Red

# Posibile opțiuni de culori
const P1_COLORS = {
	"Albastru": Color("0088ff"),
	"Verde": Color("22cc55")
}

const P2_COLORS = {
	"Roșu": Color("ff3344"),
	"Galben": Color("ffcc00")
}

# Mod de joc
var is_lan_play: bool = false
var is_host: bool = false

# Lista de nivele din joc (calea scenelor)
const LEVELS = [
	"res://src/levels/Level1_Stencil.tscn",
	"res://src/levels/Level2_Transport.tscn",
	"res://src/levels/Level3_Trigger.tscn"
]

var current_level_index: int = 0
var max_unlocked_level_index: int = 0
var remove_ads_purchased: bool = false

func _ready() -> void:
	pass

func unlock_next_level() -> void:
	var next_idx = current_level_index + 1
	if next_idx > max_unlocked_level_index and next_idx < LEVELS.size():
		max_unlocked_level_index = next_idx

func start_game() -> void:
	current_level_index = 0
	load_level(LEVELS[current_level_index])

func load_level(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)
	level_changed.emit(level_path)

func next_level() -> void:
	current_level_index += 1
	if current_level_index < LEVELS.size():
		var ad_manager = get_node_or_null("/root/AdManager")
		if ad_manager:
			ad_manager.try_show_interstitial(func():
				load_level(LEVELS[current_level_index])
			)
		else:
			load_level(LEVELS[current_level_index])
	else:
		# Joc Finalizat
		get_tree().change_scene_to_file("res://src/levels/GameCompleted.tscn")

func reset_level() -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		get_tree().reload_current_scene()

func go_to_lobby() -> void:
	is_lan_play = false
	is_host = false
	get_tree().change_scene_to_file("res://src/ui/LobbyMenu.tscn")
