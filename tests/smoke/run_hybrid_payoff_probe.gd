extends SceneTree

func _count_effect_resolves(event_stream: Array, source_id: String) -> int:
	var count: int = 0
	for event in event_stream:
		if str(event.get("kind", "")) != "effect_resolve":
			continue
		var payload: Dictionary = event.get("payload", {})
		var item: Dictionary = payload.get("item", {})
		if str(item.get("source_instance_id", "")) == source_id:
			count += 1
	return count

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame

	node.call("reset_battle", 20260405)
	var dls: Variant = node.get("dls")
	dls.hand = [
		"gem_hybrid_ruby_strike_a",
		"gem_hybrid_sapphire_guard_a",
		"gem_hybrid_focus_guard_a",
		"gem_hybrid_sapphire_burst_a",
	]
	node.set("energy", 10)
	node.call("refresh_hud")

	var hybrid_button_text: String = ""
	var hand_button_node: Node = node.get_node_or_null("CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1")
	if hand_button_node is Button:
		hybrid_button_text = (hand_button_node as Button).text

	node.call("player_play_card", "gem_hybrid_ruby_strike_a")
	node.call("player_play_card", "gem_hybrid_sapphire_guard_a")
	node.call("player_play_card", "gem_hybrid_focus_guard_a")
	node.call("player_play_card", "gem_hybrid_sapphire_burst_a")

	var vm: Dictionary = node.call("get_view_model")
	var event_stream: Array = node.get("event_stream")
	var payload: Dictionary = {
		"enemy_hp_after": int(vm.get("enemy_hp", -1)),
		"player_block_after": int(vm.get("player_block", -1)),
		"focus_after": int(vm.get("focus", -1)),
		"stack_after": vm.get("gem_stack", []),
		"resolve_count_ruby_strike": _count_effect_resolves(event_stream, "gem_hybrid_ruby_strike_a"),
		"resolve_count_sapphire_guard": _count_effect_resolves(event_stream, "gem_hybrid_sapphire_guard_a"),
		"resolve_count_focus_guard": _count_effect_resolves(event_stream, "gem_hybrid_focus_guard_a"),
		"resolve_count_sapphire_burst": _count_effect_resolves(event_stream, "gem_hybrid_sapphire_burst_a"),
		"hybrid_button_text": hybrid_button_text,
	}
	print("HYBRID_PAYOFF_PROBE=" + JSON.stringify(payload))
	quit()
