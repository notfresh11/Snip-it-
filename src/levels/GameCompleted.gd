extends Control

@onready var btn_menu: Button = $CenterContainer/VBox/BtnMenu

func _ready() -> void:
	btn_menu.pressed.connect(_on_menu_pressed)

func _on_menu_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.go_to_lobby()
