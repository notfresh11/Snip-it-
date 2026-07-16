extends BaseLevel

func _ready() -> void:
	super._ready()

	# Generăm șablonul programatic: Pătrat mușcat de un cerc
	# Un pătrat de 80x80 în coordonate locale ale StencilShape
	var sq = PackedVector2Array([
		Vector2(-40, -40),
		Vector2(40, -40),
		Vector2(40, 40),
		Vector2(-40, 40)
	])

	# Cerc de rază 32, plasat la marginea de sus (0, -40) pentru a "mușca" din pătrat
	var circle_pts = PackedVector2Array()
	var steps = 24
	for i in range(steps):
		var angle = i * TAU / steps
		circle_pts.append(Vector2(0, -40) + Vector2(cos(angle), sin(angle)) * 32)

	var clipped = Geometry2D.clip_polygons(sq, circle_pts)
	if clipped.size() > 0:
		var stencil = get_node_or_null("StencilShape")
		if stencil:
			# Actualizează poligonul șablonului
			stencil.polygon = clipped[0]

			# Recalculează aria țintă la nivel global pentru determinarea corectă a progresului de acoperire
			var global_pts = stencil.to_global_points(clipped[0], stencil.global_transform)
			stencil.target_area = stencil.get_polygon_area(global_pts)
