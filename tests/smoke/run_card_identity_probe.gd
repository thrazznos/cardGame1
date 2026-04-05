extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	var payload: Dictionary = {
		"strike_text": hud.call("_card_button_text", "strike_01"),
		"defend_text": hud.call("_card_button_text", "defend_01"),
		"utility_text": hud.call("_card_button_text", "scheme_flow"),
		"strike_tooltip": hud.call("_card_tooltip", "strike_01"),
		"defend_tooltip": hud.call("_card_tooltip", "defend_01"),
		"utility_tooltip": hud.call("_card_tooltip", "scheme_flow"),
	}
	print("CARD_IDENTITY_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
