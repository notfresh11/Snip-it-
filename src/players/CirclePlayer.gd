extends BasePlayer
class_name CirclePlayer

func _init() -> void:
	shape_type = "Circle"

	var pts = PackedVector2Array()
	var steps = 24
	for i in range(steps):
		var angle = i * TAU / steps
		pts.append(Vector2(cos(angle), sin(angle)) * 40)

	original_polygon = pts
