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

func _ready() -> void:
	# Ascundem overlay-urile la pornire
	ad_overlay.visible = false
	partner_waiting_overlay.visible = false
	hint_popup.visible = false

	# Setăm controalele vizibile în funcție de LAN vs Local
	setup_controls_visibility()

	# Conectare semnale AdManager
	AdManager.ad_overlay_toggled.connect(_on_ad_overlay_toggled)
	AdManager.remove_ads_status_changed.connect(_on_remove_ads_status_changed)

	# Conectare butoane interfață
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_remove_ads.pressed.connect(_on_remove_ads_pressed)
	btn_lobby.pressed.connect(_on_lobby_pressed)
	btn_close_hint.pressed.connect(func(): hint_popup.visible = false)

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

	_on_remove_ads_status_changed()

func _trigger_action(action: String) -> void:
	Input.action_press(action)
	get_tree().create_timer(0.05).timeout.connect(func(): Input.action_release(action))

func setup_controls_visibility() -> void:
	if GameManager.is_lan_play:
		# În LAN, afișăm doar controalele locale ale jucătorului
		if GameManager.is_host:
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
	if GameManager.remove_ads_purchased:
		btn_remove_ads.text = "Remove Ads: CUMPĂRAT"
		btn_remove_ads.modulate = Color.GREEN
	else:
		btn_remove_ads.text = "Cumpără: Remove Ads ($1.99)"
		btn_remove_ads.modulate = Color.WHITE

func _on_remove_ads_pressed() -> void:
	AdManager.toggle_remove_ads()

func _on_reset_pressed() -> void:
	# Trigger reset pe ambele caractere local
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p is BasePlayer:
			p.trigger_reset_local()

func _on_lobby_pressed() -> void:
	GameManager.go_to_lobby()

# --- Hint Ads / Rewarded ---

func _on_hint_pressed() -> void:
	if GameManager.is_lan_play:
		rpc("partner_watching_ad", true)

	AdManager.try_show_rewarded_hint(func():
		if GameManager.is_lan_play:
			rpc("partner_watching_ad", false)
		show_level_hint()
	)

@rpc("any_peer", "call_local", "reliable")
func partner_watching_ad(active: bool) -> void:
	if not multiplayer.is_server() or not GameManager.is_host:
		# Dacă celălalt vizualizează, arătăm ecranul de așteptare co-op prietenos
		partner_waiting_overlay.visible = active
		get_tree().paused = active

func show_level_hint() -> void:
	var level_idx = GameManager.current_level_index
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
