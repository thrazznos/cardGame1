extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	node.call("reset_battle", 1337)
	var dls: Variant = node.get("dls")
	dls.hand = ["scheme_flow"]
	dls.draw_pile = ["strike_probe"]
	dls.discard_pile = []
	dls.exhaust_pile = []
	dls.limbo = []
	node.call("refresh_hud")

	var play_result: Dictionary = node.call("player_play_card", "scheme_flow")
	var vm: Dictionary = node.call("get_view_model")
	var lines: Array = vm.get("recent_events", [])

	var effect_line: String = ""
	for line in lines:
		var rendered: String = str(line)
		if rendered.find("Resolve") >= 0:
			effect_line = rendered
			break

	var payload: Dictionary = {
		"ok": bool(play_result.get("ok", false)),
		"drawn_card": "strike_probe",
		"effect_resolve_line": effect_line,
		"recent_events": lines,
	}
	print("DRAW_LOG_PROBE=" + JSON.stringify(payload))
	quit()
