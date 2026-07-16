extends RigidBody2D
class_name PhysicalBall

var spawn_pos: Vector2

func _ready() -> void:
	spawn_pos = global_position

func _physics_process(delta: float) -> void:
	# Dacă cade în afara ecranului, respawn instant
	if global_position.y > 800:
		global_position = spawn_pos
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
