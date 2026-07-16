extends Control

@onready var mode_panel: VBoxContainer = $CenterContainer/VBoxContainer/ModePanel
@onready var lan_panel: VBoxContainer = $CenterContainer/VBoxContainer/LANPanel
@onready var color_panel: VBoxContainer = $CenterContainer/VBoxContainer/ColorPanel
@onready var level_panel: VBoxContainer = $CenterContainer/VBoxContainer/LevelPanel

@onready var btn_local: Button = $CenterContainer/VBoxContainer/ModePanel/BtnLocal
@onready var btn_lan: Button = $CenterContainer/VBoxContainer/ModePanel/BtnLAN

@onready var btn_host: Button = $CenterContainer/VBoxContainer/LANPanel/HBox/BtnHost
@onready var btn_join: Button = $CenterContainer/VBoxContainer/LANPanel/HBox/BtnJoin
@onready var server_list: ItemList = $CenterContainer/VBoxContainer/LANPanel/ServerList
@onready var status_lbl: Label = $CenterContainer/VBoxContainer/LANPanel/StatusLabel

@onready var p1_color_btn: OptionButton = $CenterContainer/VBoxContainer/ColorPanel/HBox/P1Color
@onready var p2_color_btn: OptionButton = $CenterContainer/VBoxContainer/ColorPanel/HBox/P2Color
@onready var btn_start: Button = $CenterContainer/VBoxContainer/ColorPanel/BtnStart

@onready var btn_level1: Button = $CenterContainer/VBoxContainer/LevelPanel/BtnLevel1
@onready var btn_level2: Button = $CenterContainer/VBoxContainer/LevelPanel/BtnLevel2
@onready var btn_level3: Button = $CenterContainer/VBoxContainer/LevelPanel/BtnLevel3

@onready var btn_back: Button = $CenterContainer/VBoxContainer/BtnBack

func _ready() -> void:
	# Resetează rețeaua
	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.disconnect_network()

	# Inițializare opțiuni de culori
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		p1_color_btn.clear()
		for color_name in game_manager.P1_COLORS.keys():
			p1_color_btn.add_item(color_name)

		p2_color_btn.clear()
		for color_name in game_manager.P2_COLORS.keys():
			p2_color_btn.add_item(color_name)

	# Conectare semnale
	btn_local.pressed.connect(_on_local_coop_pressed)
	btn_lan.pressed.connect(_on_lan_pressed)
	btn_host.pressed.connect(_on_host_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_back.pressed.connect(_on_back_pressed)

	p1_color_btn.item_selected.connect(_on_p1_color_selected)
	p2_color_btn.item_selected.connect(_on_p2_color_selected)

	# Conectare butoane selecție nivel
	btn_level1.pressed.connect(func(): _load_selected_level(0))
	btn_level2.pressed.connect(func(): _load_selected_level(1))
	btn_level3.pressed.connect(func(): _load_selected_level(2))

	if network_manager:
		network_manager.lan_servers_updated.connect(_on_servers_updated)
		network_manager.peer_connected_custom.connect(_on_peer_connected)
		network_manager.connection_succeeded_custom.connect(_on_connection_succeeded)
		network_manager.connection_failed_custom.connect(_on_connection_failed)

	show_panel("mode")

func show_panel(panel_name: String) -> void:
	mode_panel.visible = (panel_name == "mode")
	lan_panel.visible = (panel_name == "lan")
	color_panel.visible = (panel_name == "color")
	level_panel.visible = (panel_name == "level")
	btn_back.visible = (panel_name != "mode")

func _on_local_coop_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.is_lan_play = false
	show_panel("color")
	btn_start.disabled = false

func _on_lan_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.is_lan_play = true
	show_panel("lan")
	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.start_udp_listener()
	status_lbl.text = "Scanează rețeaua locală după servere..."

func _on_host_pressed() -> void:
	var network_manager = get_node_or_null("/root/NetworkManager")
	var game_manager = get_node_or_null("/root/GameManager")
	if network_manager:
		var err = network_manager.create_host("GamerHost")
		if err == OK:
			if game_manager:
				game_manager.is_host = true
			status_lbl.text = "Server creat! Așteaptă partenerul (Client)..."
			btn_host.disabled = true
			btn_join.disabled = true
		else:
			status_lbl.text = "Eroare la crearea serverului LAN."

func _on_join_pressed() -> void:
	var selected_items = server_list.get_selected_items()
	if selected_items.size() > 0:
		var index = selected_items[0]
		var ip = server_list.get_item_metadata(index)
		status_lbl.text = "Se conectează la " + ip + "..."
		var network_manager = get_node_or_null("/root/NetworkManager")
		if network_manager:
			var err = network_manager.join_host(ip)
			if err != OK:
				status_lbl.text = "Eroare la conectare."
	else:
		status_lbl.text = "Te rog selectează un server din listă."

func _on_servers_updated(servers: Array) -> void:
	server_list.clear()
	for s in servers:
		var idx = server_list.add_item(s["name"] + " (" + s["ip"] + ")")
		server_list.set_item_metadata(idx, s["ip"])

func _on_peer_connected(id: int) -> void:
	status_lbl.text = "Partener conectat! ID: " + str(id)
	show_panel("color")
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		btn_start.disabled = !game_manager.is_host

func _on_connection_succeeded() -> void:
	status_lbl.text = "Conectat cu succes!"
	show_panel("color")
	btn_start.disabled = true # Doar hostul pornește jocul

func _on_connection_failed() -> void:
	status_lbl.text = "Conexiune eșuată!"

func _on_p1_color_selected(index: int) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var col_name = p1_color_btn.get_item_text(index)
		game_manager.p1_color = game_manager.P1_COLORS[col_name]
		game_manager.player_colors_updated.emit()
		if game_manager.is_lan_play:
			rpc("sync_colors", game_manager.p1_color, game_manager.p2_color)

func _on_p2_color_selected(index: int) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var col_name = p2_color_btn.get_item_text(index)
		game_manager.p2_color = game_manager.P2_COLORS[col_name]
		game_manager.player_colors_updated.emit()
		if game_manager.is_lan_play:
			rpc("sync_colors", game_manager.p1_color, game_manager.p2_color)

@rpc("any_peer", "call_local", "reliable")
func sync_colors(c1: Color, c2: Color) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.p1_color = c1
		game_manager.p2_color = c2
		game_manager.player_colors_updated.emit()

# --- Selecție Nivel ---

func _on_start_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.is_lan_play:
			if game_manager.is_host:
				rpc("show_level_panel_rpc")
		else:
			show_level_panel()

@rpc("any_peer", "call_local", "reliable")
func show_level_panel_rpc() -> void:
	show_level_panel()

func show_level_panel() -> void:
	show_panel("level")
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Configurează deblocarea butoanelor conform progresului deblocate
		btn_level2.disabled = (game_manager.max_unlocked_level_index < 1)
		btn_level3.disabled = (game_manager.max_unlocked_level_index < 2)

		# Setează textul corespunzător
		btn_level2.text = "Nivelul 2: Transportul Bilei" if game_manager.max_unlocked_level_index >= 1 else "Nivelul 2 [Blocat]"
		btn_level3.text = "Nivelul 3: Tunele Înguste" if game_manager.max_unlocked_level_index >= 2 else "Nivelul 3 [Blocat]"

func _load_selected_level(index: int) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.is_lan_play:
			if game_manager.is_host:
				rpc("start_level_rpc", index)
		else:
			game_manager.current_level_index = index
			game_manager.load_level(game_manager.LEVELS[index])

@rpc("any_peer", "call_local", "reliable")
func start_level_rpc(index: int) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.current_level_index = index
		game_manager.load_level(game_manager.LEVELS[index])

func _on_back_pressed() -> void:
	if level_panel.visible:
		show_panel("color")
	elif color_panel.visible:
		if mode_panel.visible:
			pass
		else:
			var game_manager = get_node_or_null("/root/GameManager")
			if game_manager and game_manager.is_lan_play:
				show_panel("lan")
			else:
				show_panel("mode")
	else:
		var network_manager = get_node_or_null("/root/NetworkManager")
		if network_manager:
			network_manager.disconnect_network()
		show_panel("mode")
