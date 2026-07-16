extends Node

signal ad_overlay_toggled(visible: bool, countdown_text: String)
signal remove_ads_status_changed()

var is_ad_active: bool = false

# Simulează afișarea unei reclame interstițiale (la final de nivel)
func try_show_interstitial(on_complete_callback: Callable) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.remove_ads_purchased:
		on_complete_callback.call()
		return

	# Dacă nu s-a cumpărat "Remove Ads", pornește simularea unei reclame de 2 secunde
	is_ad_active = true
	ad_overlay_toggled.emit(true, "Reclamă Interstițială... Așteaptă 2s")

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		is_ad_active = false
		ad_overlay_toggled.emit(false, "")
		on_complete_callback.call()
	)

# Simulează afișarea unui Hint Ad (Rewarded) cu numărătoare inversă de 5 secunde
func try_show_rewarded_hint(on_reward_callback: Callable) -> void:
	if is_ad_active:
		return

	is_ad_active = true
	var seconds_left = 5
	ad_overlay_toggled.emit(true, "Se încarcă indiciul... " + str(seconds_left) + "s")

	var timer = get_tree().create_timer(1.0)
	var count_down_func
	count_down_func = func():
		seconds_left -= 1
		if seconds_left > 0:
			ad_overlay_toggled.emit(true, "Se încarcă indiciul... " + str(seconds_left) + "s")
			get_tree().create_timer(1.0).timeout.connect(count_down_func)
		else:
			is_ad_active = false
			ad_overlay_toggled.emit(false, "")
			on_reward_callback.call()

	timer.timeout.connect(count_down_func)

# Simulează achiziția Remove Ads (sau toggle-ul din setări)
func toggle_remove_ads() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.remove_ads_purchased = !game_manager.remove_ads_purchased
	remove_ads_status_changed.emit()

	var network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager and network_manager.is_multiplayer_active() and game_manager:
		network_manager.sync_remove_ads_status.rpc(game_manager.remove_ads_purchased)
