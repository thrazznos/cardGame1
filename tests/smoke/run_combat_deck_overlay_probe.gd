extends SceneTree

func _press_key(hud: Node, keycode: Key) -> void:
	if not hud.has_method("_unhandled_input"):
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = keycode
	hud.call("_unhandled_input", event)

func _overlay_title(overlay: Node) -> String:
	if overlay == null:
		return ""
	var title_node := overlay.get_node_or_null("Center/Panel/VBox/HeaderRow/Title")
	return title_node.text if title_node is Label else ""

func _overlay_count(overlay: Node) -> String:
	if overlay == null:
		return ""
	var count_node := overlay.get_node_or_null("Center/Panel/VBox/HeaderRow/CountLabel")
	return count_node.text if count_node is Label else ""

func _overlay_grid_count(overlay: Node) -> int:
	if overlay == null:
		return -1
	var card_grid := overlay.get_node_or_null("Center/Panel/VBox/BodyRow/CardScroll/CardGrid")
	return card_grid.get_child_count() if card_grid is GridContainer else -1

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_stage.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	root_node.call("reset_battle", 1337)
	root_node.call("refresh_hud")
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	var overlay := hud.get_node_or_null("DeckInspectionOverlay")
	var initial_visible: bool = overlay is Control and (overlay as Control).visible

	_press_key(hud, KEY_D)
	await process_frame
	overlay = hud.get_node_or_null("DeckInspectionOverlay")
	var after_deck_hotkey_visible: bool = overlay is Control and (overlay as Control).visible
	var deck_title_text: String = _overlay_title(overlay)
	var deck_count_text: String = _overlay_count(overlay)
	var deck_card_grid_count: int = _overlay_grid_count(overlay)

	var hand_before_block: Array = root_node.call("get_view_model").get("hand", []).duplicate(true)
	_press_key(hud, KEY_1)
	await process_frame
	var hand_after_block: Array = root_node.call("get_view_model").get("hand", []).duplicate(true)

	_press_key(hud, KEY_S)
	await process_frame
	overlay = hud.get_node_or_null("DeckInspectionOverlay")
	var after_discard_switch_visible: bool = overlay is Control and (overlay as Control).visible
	var discard_title_text: String = _overlay_title(overlay)
	var discard_count_text: String = _overlay_count(overlay)
	var discard_card_grid_count: int = _overlay_grid_count(overlay)

	_press_key(hud, KEY_S)
	await process_frame
	overlay = hud.get_node_or_null("DeckInspectionOverlay")
	var after_discard_toggle_close_visible: bool = overlay is Control and (overlay as Control).visible

	_press_key(hud, KEY_S)
	await process_frame
	overlay = hud.get_node_or_null("DeckInspectionOverlay")
	var discard_open_from_closed_visible: bool = overlay is Control and (overlay as Control).visible
	var discard_open_from_closed_title: String = _overlay_title(overlay)

	var payload := {
		"initial_visible": initial_visible,
		"after_deck_hotkey_visible": after_deck_hotkey_visible,
		"deck_title_text": deck_title_text,
		"deck_count_text": deck_count_text,
		"deck_card_grid_count": deck_card_grid_count,
		"hand_before_block": hand_before_block,
		"hand_after_block": hand_after_block,
		"after_discard_switch_visible": after_discard_switch_visible,
		"discard_title_text": discard_title_text,
		"discard_count_text": discard_count_text,
		"discard_card_grid_count": discard_card_grid_count,
		"after_discard_toggle_close_visible": after_discard_toggle_close_visible,
		"discard_open_from_closed_visible": discard_open_from_closed_visible,
		"discard_open_from_closed_title": discard_open_from_closed_title,
		"has_unhandled_input": hud.has_method("_unhandled_input"),
	}
	print("COMBAT_DECK_OVERLAY_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
