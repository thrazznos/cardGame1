extends SceneTree

func _press_key(node: Node, keycode: Key) -> void:
	if not node.has_method("_unhandled_input"):
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = keycode
	node.call("_unhandled_input", event)

func _init() -> void:
	var scene: PackedScene = load("res://scenes/floor/floor_run.tscn")
	var floor_run: Node = scene.instantiate()
	root.add_child(floor_run)
	await process_frame
	await process_frame

	var map_hud: Node = floor_run.get_node("MapHud")
	var overlay := floor_run.get_node_or_null("MapDeckOverlay")
	var initial_visible: bool = overlay is Control and (overlay as Control).visible

	_press_key(map_hud, KEY_D)
	await process_frame
	overlay = floor_run.get_node_or_null("MapDeckOverlay")
	var after_open_visible: bool = overlay is Control and (overlay as Control).visible
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

	_press_key(map_hud, KEY_D)
	await process_frame
	overlay = floor_run.get_node_or_null("MapDeckOverlay")
	var after_close_visible: bool = overlay is Control and (overlay as Control).visible

	var payload := {
		"initial_visible": initial_visible,
		"after_open_visible": after_open_visible,
		"title_text": title_text,
		"count_text": count_text,
		"card_grid_count": card_grid_count,
		"after_close_visible": after_close_visible,
	}
	print("MAP_DECK_OVERLAY_PROBE=" + JSON.stringify(payload))

	floor_run.queue_free()
	await process_frame
	quit()
