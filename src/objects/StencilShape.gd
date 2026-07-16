extends Area2D
class_name StencilShape

signal stencil_completed

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var label_progress: Label = $LabelProgress
@onready var border_line: Line2D = $BorderLine

var polygon: PackedVector2Array:
	get:
		return polygon_2d.polygon
	set(val):
		polygon_2d.polygon = val
		_update_border()

var target_area: float = 0.0
var current_ratio: float = 0.0
var completed_timer: float = 0.0
var is_done: bool = false

func _ready() -> void:
	# Calculează aria țintă inițială
	var global_pts = to_global_points(polygon_2d.polygon, global_transform)
	target_area = get_polygon_area(global_pts)
	_update_border()

func _process(delta: float) -> void:
	if is_done:
		return

	var players = get_tree().get_nodes_in_group("players")
	if players.size() < 2:
		return

	var p1 = players[0] as BasePlayer
	var p2 = players[1] as BasePlayer

	if not p1 or not p2:
		return

	# Obținem poligoanele globale ale ambilor jucători
	var p1_global = to_global_points(p1.polygon, p1.global_transform)
	var p2_global = to_global_points(p2.polygon, p2.global_transform)
	var stencil_global = to_global_points(polygon_2d.polygon, global_transform)

	# Îmbinăm formele jucătorilor pentru a evita dubla numărare a suprapunerilor
	var union_players = Geometry2D.merge_polygons(p1_global, p2_global)

	# Calculăm aria acoperită din șablon
	var covered_area = 0.0
	for piece in union_players:
		var intersection = Geometry2D.intersect_polygons(stencil_global, piece)
		for inter_piece in intersection:
			covered_area += get_polygon_area(inter_piece)

	current_ratio = covered_area / target_area if target_area > 0 else 0.0

	# Afișăm progresul (ex: 75%)
	var percentage = int(current_ratio * 100)
	if percentage > 100:
		percentage = 100
	label_progress.text = str(percentage) + "% / 85%"

	# Verificăm dacă depășim pragul de 85% acoperire
	if current_ratio >= 0.85:
		polygon_2d.color = Color(0.2, 0.9, 0.4, 0.4) # Schimbăm în verde deschis
		completed_timer += delta
		label_progress.text = "OK: " + "%.1f" % (3.0 - completed_timer) + "s"
		if completed_timer >= 3.0:
			is_done = true
			label_progress.text = "COMPLET!"
			stencil_completed.emit()
	else:
		polygon_2d.color = Color(1.0, 1.0, 1.0, 0.25) # Gri transparent implicit
		completed_timer = 0.0

func _update_border() -> void:
	if not border_line:
		return
	var pts = Array(polygon_2d.polygon)
	if pts.size() > 0:
		pts.append(pts[0])
	border_line.points = PackedVector2Array(pts)

func to_global_points(poly: PackedVector2Array, trans: Transform2D) -> PackedVector2Array:
	var out = PackedVector2Array()
	out.resize(poly.size())
	for i in range(poly.size()):
		out[i] = trans * poly[i]
	return out

# Shoelace formula pentru a calcula aria unui poligon 2D de orice dimensiune
func get_polygon_area(poly: PackedVector2Array) -> float:
	var n = poly.size()
	if n < 3:
		return 0.0
	var area = 0.0
	for i in range(n):
		var j = (i + 1) % n
		area += poly[i].x * poly[j].y
		area -= poly[j].x * poly[i].y
	return abs(area) / 2.0
