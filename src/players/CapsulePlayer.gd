extends BasePlayer
class_name CapsulePlayer

func _init() -> void:
	shape_type = "Capsule"

	var pts = PackedVector2Array()
	# Colț stânga-jos flat
	pts.append(Vector2(-40, 40))
	# Colț dreapta-jos flat
	pts.append(Vector2(40, 40))
	# Partea dreaptă verticală
	pts.append(Vector2(40, -10))

	# Cap rotunjit superior (semi-cerc de la unghiul 0 la -PI, i.e. 0 la -180 grade)
	var steps = 12
	for i in range(steps + 1):
		var angle = -i * PI / steps
		pts.append(Vector2(0, -10) + Vector2(cos(angle), sin(angle)) * 40)

	# Partea stângă verticală se închide automat către (-40, 40)
	original_polygon = pts
