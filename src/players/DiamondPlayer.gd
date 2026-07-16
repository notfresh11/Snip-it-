extends BasePlayer
class_name DiamondPlayer

func _init() -> void:
	shape_type = "Diamond"
	original_polygon = PackedVector2Array([
		Vector2(0, -50),
		Vector2(50, 0),
		Vector2(0, 50),
		Vector2(-50, 0)
	])
