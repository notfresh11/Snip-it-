extends BaseLevel

@onready var pressure_button: PressureButton = $PressureButton
@onready var blocking_wall: StaticBody2D = $BlockingWall
@onready var wall_visual: Polygon2D = $BlockingWall/Visual
@onready var wall_collision: CollisionShape2D = $BlockingWall/Collision
@onready var win_area: Area2D = $WinArea

var is_barrier_open: bool = false

func _ready() -> void:
	super._ready()
	pressure_button.button_pressed.connect(_on_button_pressed)
	win_area.body_entered.connect(_on_win_body_entered)

func _on_button_pressed(pressed: bool) -> void:
	is_barrier_open = pressed

	# Sincronizăm starea barierei
	wall_collision.disabled = pressed
	wall_visual.visible = !pressed

func _on_win_body_entered(body: Node2D) -> void:
	if body is BasePlayer:
		# Dacă bariera este deschisă și jucătorul trece la win area
		if is_barrier_open:
			complete_level()
