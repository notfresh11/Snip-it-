extends Area2D
class_name PressureButton

signal button_pressed(is_pressed: bool)

@onready var visual_plate: Polygon2D = $VisualPlate

var bodies_inside: int = 0
var is_pressed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	bodies_inside += 1
	update_state()

func _on_body_exited(body: Node2D) -> void:
	bodies_inside -= 1
	update_state()

func update_state() -> void:
	var target_pressed = bodies_inside > 0
	if target_pressed != is_pressed:
		is_pressed = target_pressed
		button_pressed.emit(is_pressed)

		# Animație vizuală simplă (apasă în jos cu 8 pixeli)
		if is_pressed:
			visual_plate.position.y = 8
			visual_plate.color = Color(0.2, 0.9, 0.4, 1.0) # Verde
		else:
			visual_plate.position.y = 0
			visual_plate.color = Color(0.9, 0.2, 0.3, 1.0) # Roșu
