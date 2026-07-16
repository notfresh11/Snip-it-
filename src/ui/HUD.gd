extends CanvasLayer

@onready var p1_controls: Control = $P1Controls
@onready var p2_controls: Control = $P2Controls

@onready var btn_hint: Button = $TopBar/BtnHint
@onready var btn_reset: Button = $TopBar/BtnReset
@onready var btn_remove_ads: Button = $TopBar/BtnRemoveAds
@onready var btn_lobby: Button = $TopBar/BtnLobby

@onready var ad_overlay: ColorRect = $AdOverlay
@onready var ad_label: Label = $AdOverlay/AdLabel

@onready var partner_waiting_overlay: ColorRect = $PartnerWaitingOverlay

@onready var hint_popup: ColorRect = $HintPopup
@onready var hint_label: Label = $HintPopup/VBox/HintLabel
@onready var btn_close_hint: Button = $HintPopup/VBox/BtnCloseHint

@onready var level_complete_overlay: ColorRect = $LevelCompleteOverlay
@onready var btn_next_level: Button = $LevelCompleteOverlay/VBox/BtnNextLevel

func _ready() -> void:
	# Ascundem overlay-urile la pornire
	ad_overlay.visible = false
	partner_waiting_overlay.visible = false
	hint_popup.visible = false
	level_complete_overlay.visible = false

	# Setăm controalele vizibile în funcție de LAN vs Local
	setup_controls_visibility()

	# Conectare semnale AdManager
	var ad_manager = get_node_or_null("/root/AdManager")
	if ad_manager:
		ad_manager.ad_overlay_toggled.connect(_on_ad_overlay_toggled)
		ad_manager.remove_ads_status_changed.connect(_on_remove_ads_status_changed)

	# Conectare butoane interfață
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_remove_ads.pressed.connect(_on_remove_ads_pressed)
	btn_lobby.pressed.connect(_on_lobby_pressed)
	btn_close_hint.pressed.connect(func(): hint_popup.visible = false)
	btn_next_level.pressed.connect(_go_to_next_level)

	# Conectare butoane virtuale de control pentru P1
	$P1Controls/BtnLeft.button_down.connect(func(): Input.action_press("p1_left"))
	$P1Controls/BtnLeft.button_up.connect(func(): Input.action_release("p1_left"))
	$P1Controls/BtnRight.button_down.connect(func(): Input.action_press("p1_right"))
	$P1Controls/BtnRight.button_up.connect(func(): Input.action_release("p1_right"))
	$P1Controls/BtnJump.pressed.connect(func(): _trigger_action("p1_jump"))
	$P1Controls/BtnCut.pressed.connect(func(): _trigger_action("p1_cut"))
	$P1Controls/BtnRotLeft.button_down.connect(func(): Input.action_press("p1_rotate_left"))
	$P1Controls/BtnRotLeft.button_up.connect(func(): Input.action_release("p1_rotate_left"))
	$P1Controls/BtnRotRight.button_down.connect(func(): Input.action_press("p1_rotate_right"))
	$P1Controls/BtnRotRight.button_up.connect(func(): Input.action_release("p1_rotate_right"))
	$P1Controls/BtnFocus.button_down.connect(func(): Input.action_press("p1_focus"))
	$P1Controls/BtnFocus.button_up.connect(func(): Input.action_release("p1_focus"))

	# Conectare butoane virtuale de control pentru P2
	$P2Controls/BtnLeft.button_down.connect(func(): Input.action_press("p2_left"))
	$P2Controls/BtnLeft.button_up.connect(func(): Input.action_release("p2_left"))
	$P2Controls/BtnRight.button_down.connect(func(): Input.action_press("p2_right"))
	$P2Controls/BtnRight.button_up.connect(func(): Input.action_release("p2_right"))
	$P2Controls/BtnJump.pressed.connect(func(): _trigger_action("p2_jump"))
	$P2Controls/BtnCut.pressed.connect(func(): _trigger_action("p2_cut"))
	$P2Controls/BtnRotLeft.button_down.connect(func(): Input.action_press("p2_rotate_left"))
	$P2Controls/BtnRotLeft.button_up.connect(func(): Input.action_release("p2_rotate_left"))
	$P2Controls/BtnRotRight.button_down.connect(func(): Input.action_press("p2_rotate_right"))
	$P2Controls/BtnRotRight.button_up.connect(func(): Input.action_release("p2_rotate_right"))
	$P2Controls/BtnFocus.button_down.connect(func(): Input.action_press("p2_focus"))
	$P2Controls/BtnFocus.button_up.connect(func(): Input.action_release("p2_focus"))

	_on_remove_ads_status_changed()

func _trigger_action(action: String) -> void:
	Input.action_press(action)
	get_tree().create_timer(0.05).timeout.connect(func(): Input.action_release(action))

func setup_controls_visibility() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play:
		# În LAN, afișăm doar controalele locale ale jucătorului
		if game_manager.is_host:
			p1_controls.visible = true
			p2_controls.visible = false
		else:
			p1_controls.visible = false
			p2_controls.visible = true
	else:
		# În Local Co-op, ambele seturi de controale virtuale pot fi afișate
		p1_controls.visible = true
		p2_controls.visible = true

func _on_remove_ads_status_changed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.remove_ads_purchased:
			btn_remove_ads.text = "Remove Ads: CUMPĂRAT"
			btn_remove_ads.modulate = Color.GREEN
		else:
			btn_remove_ads.text = "Cumpără: Remove Ads ($1.99)"
			btn_remove_ads.modulate = Color.WHITE

func _on_remove_ads_pressed() -> void:
	var ad_manager = get_node_or_null("/root/AdManager")
	if ad_manager:
		ad_manager.toggle_remove_ads()

func _on_reset_pressed() -> void:
	# Trigger reset pe ambele caractere local
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p is BasePlayer:
			p.trigger_reset_local()

func _on_lobby_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.go_to_lobby()

# --- Hint Ads / Rewarded ---

func _on_hint_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.is_lan_play:
		rpc("partner_watching_ad", true)

	var ad_manager = get_node_or_null("/root/AdManager")
	if ad_manager:
		ad_manager.try_show_rewarded_hint(func():
			if game_manager and game_manager.is_lan_play:
				rpc("partner_watching_ad", false)
			show_level_hint()
		)

@rpc("any_peer", "call_local", "reliable")
func partner_watching_ad(active: bool) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if not multiplayer.is_server() or not game_manager.is_host:
			# Dacă celălalt vizualizează, arătăm ecranul de așteptare co-op prietenos
			partner_waiting_overlay.visible = active
			get_tree().paused = active

func show_level_hint() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	var level_idx = game_manager.current_level_index if game_manager else 0
	var hint_text = ""
	match level_idx:
		0:
			hint_text = "INDICIU NIVEL 1 (Șablon):\n\nPotriviți-vă exact în șablonul punctat! Unul dintre voi trebuie să îl decupeze pe celălalt pentru a se încadra în forme."
		1:
			hint_text = "INDICIU NIVEL 2 (Transport):\n\nDecupează o formă de cupă/căuș în corpul Jucătorului 2. Jucătorul 2 transportă bila în siguranță pe capul lui!"
		2:
			hint_text = "INDICIU NIVEL 3 (Trigger):\n\nJucătorul 2 îl decupează pe Jucătorul 1 până când devine o fâșie extrem de subțire de ac geometric pentru a intra în tunelul strâmt."
		_:
			hint_text = "Colaborați și decupați-vă formele pentru a rezolva puzzle-ul!"

	hint_label.text = hint_text
	hint_popup.visible = true

# --- Reclame simulare ---

func _on_ad_overlay_toggled(visible: bool, countdown_text: String) -> void:
	ad_overlay.visible = visible
	ad_label.text = countdown_text
	get_tree().paused = visible # Pune pauză fizicii și jocului în timp ce rulează reclama

# --- Tranziție Victorie Nivel (Enter/Space) ---

func show_level_completed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.unlock_next_level()
	level_complete_overlay.visible = true

func _input(event: InputEvent) -> void:
	if level_complete_overlay and level_complete_overlay.visible and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_go_to_next_level()

func _go_to_next_level() -> void:
	level_complete_overlay.visible = false
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.next_level()
