extends Control

@onready var mode_panel: VBoxContainer = $CenterContainer/VBoxContainer/ModePanel
@onready var lan_panel: VBoxContainer = $CenterContainer/VBoxContainer/LANPanel
@onready var color_panel: VBoxContainer = $CenterContainer/VBoxContainer/ColorPanel

@onready var btn_local: Button = $CenterContainer/VBoxContainer/ModePanel/BtnLocal
@onready var btn_lan: Button = $CenterContainer/VBoxContainer/ModePanel/BtnLAN

@onready var btn_host: Button = $CenterContainer/VBoxContainer/LANPanel/HBox/BtnHost
@onready var btn_join: Button = $CenterContainer/VBoxContainer/LANPanel/HBox/BtnJoin
@onready var server_list: ItemList = $CenterContainer/VBoxContainer/LANPanel/ServerList
@onready var status_lbl: Label = $CenterContainer/VBoxContainer/LANPanel/StatusLabel

@onready var p1_color_btn: OptionButton = $CenterContainer/VBoxContainer/ColorPanel/HBox/P1Color
@onready var p2_color_btn: OptionButton = $CenterContainer/VBoxContainer/ColorPanel/HBox/P2Color
@onready var btn_start: Button = $CenterContainer/VBoxContainer/ColorPanel/BtnStart
@onready var btn_back: Button = $CenterContainer/VBoxContainer/BtnBack

func _ready() -> void:
	# Resetează rețeaua
	NetworkManager.disconnect_network()

	# Inițializare opțiuni de culori
	p1_color_btn.clear()
	for color_name in GameManager.P1_COLORS.keys():
		p1_color_btn.add_item(color_name)

	p2_color_btn.clear()
	for color_name in GameManager.P2_COLORS.keys():
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

	NetworkManager.lan_servers_updated.connect(_on_servers_updated)
	NetworkManager.peer_connected_custom.connect(_on_peer_connected)
	NetworkManager.connection_succeeded_custom.connect(_on_connection_succeeded)
	NetworkManager.connection_failed_custom.connect(_on_connection_failed)

	show_panel("mode")

func show_panel(panel_name: String) -> void:
	mode_panel.visible = (panel_name == "mode")
	lan_panel.visible = (panel_name == "lan")
	color_panel.visible = (panel_name == "color")
	btn_back.visible = (panel_name != "mode")

func _on_local_coop_pressed() -> void:
	GameManager.is_lan_play = false
	show_panel("color")
	btn_start.disabled = false

func _on_lan_pressed() -> void:
	GameManager.is_lan_play = true
	show_panel("lan")
	NetworkManager.start_udp_listener()
	status_lbl.text = "Scanează rețeaua locală după servere..."

func _on_host_pressed() -> void:
	var err = NetworkManager.create_host("GamerHost")
	if err == OK:
		GameManager.is_host = true
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
		var err = NetworkManager.join_host(ip)
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
	# Trecem la panoul de culori
	show_panel("color")
	# Host-ul are dreptul să pornească jocul
	btn_start.disabled = !GameManager.is_host

func _on_connection_succeeded() -> void:
	status_lbl.text = "Conectat cu succes!"
	show_panel("color")
	btn_start.disabled = true # Doar hostul pornește jocul

func _on_connection_failed() -> void:
	status_lbl.text = "Conexiune eșuată!"

func _on_p1_color_selected(index: int) -> void:
	var col_name = p1_color_btn.get_item_text(index)
	GameManager.p1_color = GameManager.P1_COLORS[col_name]
	GameManager.player_colors_updated.emit()
	if GameManager.is_lan_play:
		rpc("sync_colors", GameManager.p1_color, GameManager.p2_color)

func _on_p2_color_selected(index: int) -> void:
	var col_name = p2_color_btn.get_item_text(index)
	GameManager.p2_color = GameManager.P2_COLORS[col_name]
	GameManager.player_colors_updated.emit()
	if GameManager.is_lan_play:
		rpc("sync_colors", GameManager.p1_color, GameManager.p2_color)

@rpc("any_peer", "call_local", "reliable")
func sync_colors(c1: Color, c2: Color) -> void:
	GameManager.p1_color = c1
	GameManager.p2_color = c2
	GameManager.player_colors_updated.emit()

func _on_start_pressed() -> void:
	if GameManager.is_lan_play:
		rpc("start_game_rpc")
	else:
		GameManager.start_game()

@rpc("any_peer", "call_local", "reliable")
func start_game_rpc() -> void:
	GameManager.start_game()

func _on_back_pressed() -> void:
	NetworkManager.disconnect_network()
	show_panel("mode")
