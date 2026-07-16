extends CharacterBody2D
class_name BasePlayer

@export var player_id: int = 1
@export var shape_type: String = "Square"

# Proprietăți fizice de bază
const SPEED = 250.0
const JUMP_VELOCITY = -450.0
const ROTATION_SPEED = 2.5
const GRAVITY = 1200.0

# Referințe noduri interne
@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var outline_line: Line2D = $OutlineLine
@onready var face_sprite: Sprite2D = $FaceSprite
@onready var crumbs_particles: CPUParticles2D = $CrumbsParticles

# Forme geometrice
var original_polygon: PackedVector2Array
var polygon: PackedVector2Array:
	get:
		return polygon_2d.polygon
	set(val):
		polygon_2d.polygon = val
		if collision_polygon_2d:
			collision_polygon_2d.polygon = val
		update_outline()
		update_face_position()

# Gestionarea stării feței
var face_normal: Texture2D
var face_worried: Texture2D
var face_shocked: Texture2D

var is_shocked: bool = false
var reset_timer: float = 0.0
const RESET_HOLD_DURATION = 0.8 # secunde de ținut apăsat reset

# Punct de spawn
var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position

	# Configurare straturi și măști de coliziune conform planului de design
	# Layer 1: Mediul (sticle, podele, tavan) - valoare 1
	# Layer 2: Player 1 - valoare 2
	# Layer 3: Player 2 - valoare 4
	# Layer 4: Bile fizice - valoare 8
	if player_id == 1:
		collision_layer = 2
		collision_mask = 1 + 8 # Mediul (1) + Bile (8). Nu se ciocnește cu Player 2.
	else:
		collision_layer = 4
		collision_mask = 1 + 8 # Mediul (1) + Bile (8). Nu se ciocnește cu Player 1.

	# Încărcăm fețele corespunzătoare
	load_textures()

	# Dacă original_polygon nu a fost setat de o clasă derivată, îl salvăm pe cel curent
	if original_polygon.size() == 0:
		original_polygon = polygon_2d.polygon

	polygon = original_polygon

	# Setează culoarea poligonului
	update_player_color()
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.player_colors_updated.connect(update_player_color)

	# Configurare contur
	outline_line.width = 4.0
	outline_line.joint_mode = Line2D.LINE_JOINT_ROUND
	outline_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outline_line.end_cap_mode = Line2D.LINE_CAP_ROUND

	update_outline()
	update_face_position()

	# Configurare programatică MultiplayerSynchronizer
	if has_node("MultiplayerSynchronizer"):
		var sync_node = get_node("MultiplayerSynchronizer")
		var config = SceneReplicationConfig.new()
		config.add_property(NodePath(".:global_position"))
		config.add_property(NodePath(".:rotation"))
		config.add_property(NodePath(".:scale"))
		config.add_property(NodePath(".:velocity"))
		sync_node.replication_config = config

func load_textures() -> void:
	if player_id == 1:
		face_normal = load("res://Assets/Shape Char/PNG/Double/face_a.png")
		face_worried = load("res://Assets/Shape Char/PNG/Double/face_f.png")
		face_shocked = load("res://Assets/Shape Char/PNG/Double/face_g.png")
	else:
		face_normal = load("res://Assets/Shape Char/PNG/Double/face_b.png")
		face_worried = load("res://Assets/Shape Char/PNG/Double/face_h.png")
		face_shocked = load("res://Assets/Shape Char/PNG/Double/face_l.png")

	face_sprite.texture = face_normal

func update_player_color() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	var col = Color("0088ff")
	if game_manager:
		col = game_manager.p1_color if player_id == 1 else game_manager.p2_color
	else:
		col = Color("0088ff") if player_id == 1 else Color("ff3344")

	polygon_2d.color = col
	outline_line.default_color = col.darkened(0.4)
	crumbs_particles.color = col

func update_outline() -> void:
	if not outline_line:
		return
	var pts = Array(polygon)
	if pts.size() > 0:
		pts.append(pts[0]) # Închidem bucla
	outline_line.points = PackedVector2Array(pts)

func update_face_position() -> void:
	if not face_sprite:
		return
	var centroid = calculate_centroid(polygon)
	face_sprite.position = centroid

func calculate_centroid(poly: PackedVector2Array) -> Vector2:
	if poly.size() == 0:
		return Vector2.ZERO
	var sum = Vector2.ZERO
	for pt in poly:
		sum += pt
	return sum / poly.size()

func _physics_process(delta: float) -> void:
	# Autoritate în rețea
	var is_local_controlled = true
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play:
		is_local_controlled = is_multiplayer_authority()

	if not is_local_controlled:
		# Actualizează fața în funcție de overlap chiar dacă e controlat de rețea
		check_and_update_face_state()
		return

	# Adăugăm gravitația
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Gestionare input
	var prefix = "p1_" if player_id == 1 else "p2_"

	# Mișcare stânga/dreapta
	var direction = Input.get_axis(prefix + "left", prefix + "right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Săritură
	if Input.is_action_just_pressed(prefix + "jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Rotație Fină
	var rotation_input = 0.0
	if Input.is_action_pressed(prefix + "rotate_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed(prefix + "rotate_right"):
		rotation_input += 1.0

	if rotation_input != 0:
		rotation += rotation_input * ROTATION_SPEED * delta

	# Squash & Stretch (Ghemuire/Alungire) - Scalăm doar elementele vizuale pentru a păstra coliziunile fizice stabile
	var target_scale = Vector2.ONE
	if Input.is_action_pressed(prefix + "down"):
		# Ghemuit (squash)
		target_scale = Vector2(1.4, 0.5)
	elif velocity.y < -50:
		# Alungit în aer (stretch)
		target_scale = Vector2(0.8, 1.3)

	var current_visual_scale = polygon_2d.scale
	var next_visual_scale = current_visual_scale.lerp(target_scale, 15.0 * delta)

	polygon_2d.scale = next_visual_scale
	outline_line.scale = next_visual_scale
	face_sprite.scale = next_visual_scale

	move_and_slide()

	# Acțiunea de tăiere (Cut Action)
	if Input.is_action_just_pressed(prefix + "cut"):
		try_cut_other()

	# Reîntoarcere la forma inițială (Reset)
	if Input.is_action_pressed(prefix + "reset"):
		reset_timer += delta
		if reset_timer >= RESET_HOLD_DURATION:
			reset_timer = 0.0
			trigger_reset_local()
	else:
		reset_timer = 0.0

	# Actualizează stările feței
	check_and_update_face_state()

func check_and_update_face_state() -> void:
	if is_shocked:
		return # Păstrăm fața de șoc

	# Verificăm dacă suntem aproape de celălalt jucător și există risc de tăiere (overlap)
	var other = get_other_player()
	if other:
		# Să ne orientăm fața ușor spre celălalt jucător (privire curioasă/îngrijorată)
		var to_other = other.global_position - global_position
		face_sprite.flip_h = to_other.x < 0

		var dist = global_position.distance_to(other.global_position)
		if dist < 250:
			var self_poly_global = to_global_points(polygon, global_transform)
			var other_poly_global = to_global_points(other.polygon, other.global_transform)
			var intersect = Geometry2D.intersect_polygons(self_poly_global, other_poly_global)
			if intersect.size() > 0:
				face_sprite.texture = face_worried
				return

	face_sprite.texture = face_normal

func get_other_player() -> BasePlayer:
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p != self and p is BasePlayer:
			return p
	return null

# --- Motorul de tăiere (Clipping Engine) ---

func try_cut_other() -> void:
	var other = get_other_player()
	if not other:
		return

	var dist = global_position.distance_to(other.global_position)
	if dist > 300:
		return

	var cutter_poly_global = to_global_points(polygon, global_transform)
	var target_poly_global = to_global_points(other.polygon, other.global_transform)

	var intersection = Geometry2D.intersect_polygons(target_poly_global, cutter_poly_global)
	if intersection.size() > 0:
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.is_lan_play:
			other.rpc("apply_cut_from_rpc", cutter_poly_global)
		else:
			other.apply_cut(cutter_poly_global)

@rpc("any_peer", "call_local", "reliable")
func apply_cut_from_rpc(cutter_poly_global: PackedVector2Array) -> void:
	apply_cut(cutter_poly_global)

func apply_cut(cutter_poly_global: PackedVector2Array) -> void:
	var target_poly_global = to_global_points(polygon, global_transform)
	var results: Array[PackedVector2Array] = Geometry2D.clip_polygons(target_poly_global, cutter_poly_global)

	if results.size() > 0:
		# Păstrăm fragmentul cel mai mare
		var max_area = -1.0
		var best_poly: PackedVector2Array
		for r in results:
			var area = get_polygon_area(r)
			if area > max_area:
				max_area = area
				best_poly = r

		# Verificăm dacă fragmentul rămas este prea mic (autodistrugere)
		var original_area = get_polygon_area(to_global_points(original_polygon, Transform2D.IDENTITY))
		if max_area < original_area * 0.12 or max_area < 500:
			trigger_respawn()
		else:
			var target_local_poly = to_local_points(best_poly, global_transform)
			update_shape_local(target_local_poly)

			# Efecte de tăiere
			play_snipped_effects()

			# Dacă suntem în LAN, sincronizăm forma către celălalt jucător
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager and game_manager.is_lan_play and is_multiplayer_authority():
				rpc("update_shape_rpc", target_local_poly)
	else:
		trigger_respawn()

@rpc("any_peer", "call_local", "reliable")
func update_shape_rpc(new_points: PackedVector2Array) -> void:
	update_shape_local(new_points)
	play_snipped_effects()

func update_shape_local(new_points: PackedVector2Array) -> void:
	polygon = new_points

func play_snipped_effects() -> void:
	# Redă animația de speriat pe față
	is_shocked = true
	face_sprite.texture = face_shocked
	crumbs_particles.emitting = true

	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		is_shocked = false
		face_sprite.texture = face_normal
	)

# --- Respawn și Reset ---

func trigger_respawn() -> void:
	# Particule de distrugere masivă
	crumbs_particles.amount = 50
	crumbs_particles.emitting = true

	# Deplasează înapoi la spawn
	global_position = spawn_position
	rotation = 0.0
	velocity = Vector2.ZERO

	# Reinstaurăm forma originală
	polygon = original_polygon
	crumbs_particles.amount = 20

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play and is_multiplayer_authority():
		rpc("sync_respawn_rpc", global_position)

@rpc("any_peer", "call_local", "reliable")
func sync_respawn_rpc(pos: Vector2) -> void:
	global_position = pos
	rotation = 0.0
	velocity = Vector2.ZERO
	polygon = original_polygon

func trigger_reset_local() -> void:
	polygon = original_polygon
	play_snipped_effects()

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play and is_multiplayer_authority():
		rpc("sync_reset_rpc")

@rpc("any_peer", "call_local", "reliable")
func sync_reset_rpc() -> void:
	polygon = original_polygon
	play_snipped_effects()

# --- Transformări Geometrice Utile ---

func to_global_points(poly: PackedVector2Array, trans: Transform2D) -> PackedVector2Array:
	var out = PackedVector2Array()
	out.resize(poly.size())
	for i in range(poly.size()):
		out[i] = trans * poly[i]
	return out

func to_local_points(poly: PackedVector2Array, trans: Transform2D) -> PackedVector2Array:
	var inv = trans.inverse()
	var out = PackedVector2Array()
	out.resize(poly.size())
	for i in range(poly.size()):
		out[i] = inv * poly[i]
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
