extends Control

@onready var btn_menu: Button = $CenterContainer/VBox/BtnMenu

func _ready() -> void:
	btn_menu.pressed.connect(_on_menu_pressed)

func _on_menu_pressed() -> void:
	GameManager.go_to_lobby()
