extends SceneTree

func _press_key(hud: Node, keycode: Key) -> void:
	if not hud.has_method("_unhandled_input"):
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = keycode
	hud.call("_unhandled_input", event)

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
	var hint_snapshot: Dictionary = hud.get("vm") if hud.get("vm") is Dictionary else {}

	_press_key(hud, KEY_D)
	await process_frame
	overlay = hud.get_node_or_null("DeckInspectionOverlay")
	var after_hotkey_open_visible: bool = overlay is Control and (overlay as Control).visible
	var title_text: String = ""
	var count_text: String = ""
	var card_grid_count: int = -1
	if overlay != null:
		var title_node := overlay.get_node_or_null("Center/Panel/VBox/HeaderRow/Title")
		if title_node is Label:
			title_text = title_node.text
		var count_node := overlay.get_node_or_null("Center/Panel/VBox/HeaderRow/CountLabel")
		if count_node is Label:
			count_text = count_node.text
		var card_grid := overlay.get_node_or_null("Center/Panel/VBox/BodyRow/CardScroll/CardGrid")
		if card_grid is GridContainer:
			card_grid_count = card_grid.get_child_count()

	var hand_before_block: Array = root_node.call("get_view_model").get("hand", []).duplicate(true)
	_press_key(hud, KEY_1)
	await process_frame
	var hand_after_block: Array = root_node.call("get_view_model").get("hand", []).duplicate(true)

	_press_key(hud, KEY_D)
	await process_frame
	overlay = hud.get_node_or_null("DeckInspectionOverlay")
	var after_hotkey_close_visible: bool = overlay is Control and (overlay as Control).visible

	var payload := {
		"initial_visible": initial_visible,
		"after_hotkey_open_visible": after_hotkey_open_visible,
		"title_text": title_text,
		"count_text": count_text,
		"card_grid_count": card_grid_count,
		"hand_before_block": hand_before_block,
		"hand_after_block": hand_after_block,
		"after_hotkey_close_visible": after_hotkey_close_visible,
		"has_unhandled_input": hud.has_method("_unhandled_input"),
		"hint_has_deck": true,
		"vm_turn": int(hint_snapshot.get("turn", 0)),
	}
	print("COMBAT_DECK_OVERLAY_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
