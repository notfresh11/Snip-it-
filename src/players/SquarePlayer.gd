extends BasePlayer
class_name SquarePlayer

func _init() -> void:
	shape_type = "Square"
	original_polygon = PackedVector2Array([
		Vector2(-40, -40),
		Vector2(40, -40),
		Vector2(40, 40),
		Vector2(-40, 40)
	])
