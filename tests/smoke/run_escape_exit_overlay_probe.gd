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
	var exit_overlay := floor_run.get_node_or_null("ExitOverlay")
	var keybindings_overlay := floor_run.get_node_or_null("KeybindingsOverlay")
	var initial_exit_visible: bool = exit_overlay is Control and (exit_overlay as Control).visible
	var initial_keybindings_visible: bool = keybindings_overlay is Control and (keybindings_overlay as Control).visible

	_press_key(map_hud, KEY_F2)
	await process_frame
	keybindings_overlay = floor_run.get_node_or_null("KeybindingsOverlay")
	var keybindings_visible_after_f9: bool = keybindings_overlay is Control and (keybindings_overlay as Control).visible

	_press_key(floor_run, KEY_ESCAPE)
	await process_frame
	keybindings_overlay = floor_run.get_node_or_null("KeybindingsOverlay")
	exit_overlay = floor_run.get_node_or_null("ExitOverlay")
	var keybindings_visible_after_escape: bool = keybindings_overlay is Control and (keybindings_overlay as Control).visible
	var exit_visible_after_closing_keybindings: bool = exit_overlay is Control and (exit_overlay as Control).visible

	_press_key(floor_run, KEY_ESCAPE)
	await process_frame
	exit_overlay = floor_run.get_node_or_null("ExitOverlay")
	var exit_visible_after_first_escape: bool = exit_overlay is Control and (exit_overlay as Control).visible

	_press_key(floor_run, KEY_ESCAPE)
	await process_frame
	exit_overlay = floor_run.get_node_or_null("ExitOverlay")
	var exit_visible_after_second_escape: bool = exit_overlay is Control and (exit_overlay as Control).visible

	floor_run.call("map_commit_room", int(floor_run.call("get_floor_view_model").get("legal_moves", [0])[0]))
	await process_frame
	await process_frame
	var combat_hud: Node = floor_run.get_node("CombatStage/CombatHud")
	_press_key(combat_hud, KEY_D)
	await process_frame
	var deck_overlay := combat_hud.get_node_or_null("DeckInspectionOverlay")
	var deck_visible_before_escape: bool = deck_overlay is Control and (deck_overlay as Control).visible

	_press_key(floor_run, KEY_ESCAPE)
	await process_frame
	deck_overlay = combat_hud.get_node_or_null("DeckInspectionOverlay")
	exit_overlay = floor_run.get_node_or_null("ExitOverlay")
	var deck_visible_after_escape: bool = deck_overlay is Control and (deck_overlay as Control).visible
	var exit_visible_after_closing_deck: bool = exit_overlay is Control and (exit_overlay as Control).visible

	_press_key(floor_run, KEY_ESCAPE)
	await process_frame
	exit_overlay = floor_run.get_node_or_null("ExitOverlay")
	var exit_visible_after_opening_from_combat: bool = exit_overlay is Control and (exit_overlay as Control).visible

	var payload := {
		"initial_exit_visible": initial_exit_visible,
		"initial_keybindings_visible": initial_keybindings_visible,
		"keybindings_visible_after_f9": keybindings_visible_after_f9,
		"keybindings_visible_after_escape": keybindings_visible_after_escape,
		"exit_visible_after_closing_keybindings": exit_visible_after_closing_keybindings,
		"exit_visible_after_first_escape": exit_visible_after_first_escape,
		"exit_visible_after_second_escape": exit_visible_after_second_escape,
		"deck_visible_before_escape": deck_visible_before_escape,
		"deck_visible_after_escape": deck_visible_after_escape,
		"exit_visible_after_closing_deck": exit_visible_after_closing_deck,
		"exit_visible_after_opening_from_combat": exit_visible_after_opening_from_combat,
	}
	print("ESCAPE_EXIT_OVERLAY_PROBE=" + JSON.stringify(payload))

	floor_run.queue_free()
	await process_frame
	quit()
