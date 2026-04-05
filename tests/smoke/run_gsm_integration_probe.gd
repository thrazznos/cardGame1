extends SceneTree

func _find_effect_resolve_reason(event_stream: Array, source_id: String) -> String:
	for event in event_stream:
		if str(event.get("kind", "")) != "effect_resolve":
			continue
		var payload: Dictionary = event.get("payload", {})
		var item: Dictionary = payload.get("item", {})
		if str(item.get("source_instance_id", "")) != source_id:
			continue
		var result: Dictionary = payload.get("result", {})
		if not bool(result.get("ok", true)):
			return str(result.get("reason", ""))
	return ""

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	node.call("reset_battle", 1337)
	var dls: Variant = node.get("dls")
	dls.hand = [
		"gem_produce_ruby_a",
		"gem_produce_sapphire_a",
		"gem_offset_consume_ruby_fail",
		"gem_focus_a",
		"gem_offset_consume_ruby_ok",
	]
	node.set("energy", 10)
	node.call("refresh_hud")

	node.call("player_play_card", "gem_produce_ruby_a")
	node.call("player_play_card", "gem_produce_sapphire_a")
	node.call("player_play_card", "gem_offset_consume_ruby_fail")
	var event_stream_after_fail: Array = node.get("event_stream")
	var focus_gate_reason: String = _find_effect_resolve_reason(event_stream_after_fail, "gem_offset_consume_ruby_fail")

	node.call("player_play_card", "gem_focus_a")
	var vm_after_focus: Dictionary = node.call("get_view_model")
	var focus_after_focus_card: int = int(vm_after_focus.get("focus", -1))

	node.call("player_play_card", "gem_offset_consume_ruby_ok")
	var vm_after_consume: Dictionary = node.call("get_view_model")

	var payload: Dictionary = {
		"focus_gate_reason": focus_gate_reason,
		"focus_after_focus_card": focus_after_focus_card,
		"focus_after_advanced_consume": int(vm_after_consume.get("focus", -1)),
		"stack_after_advanced_consume": vm_after_consume.get("gem_stack", []),
		"vm_stack_top": vm_after_consume.get("gem_stack_top", []),
	}

	print("GSM_INTEGRATION_PROBE=" + JSON.stringify(payload))
	quit()
