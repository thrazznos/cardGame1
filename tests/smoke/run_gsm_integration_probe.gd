extends SceneTree

func _find_play_reject_reason(event_stream: Array, source_id: String) -> String:
	for event in event_stream:
		if str(event.get("kind", "")) != "play_reject":
			continue
		var payload: Dictionary = event.get("payload", {})
		if str(payload.get("instance_id", "")) != source_id and str(payload.get("card_id", "")) != source_id:
			continue
		return str(payload.get("reason", ""))
	return ""

func _find_hand_button(hud: Node, instance_id: String) -> Button:
	var buttons_node: Node = hud.get_node_or_null("Margin/VBox/HandPanel/HandVBox/HandButtons")
	if buttons_node == null:
		return null
	for child in buttons_node.get_children():
		if child is Button and str((child as Button).get_meta("instance_id", "")) == instance_id:
			return child as Button
	return null

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
	var hud: Node = node.get_node("CombatHud")

	var gem_producer_button_text: String = ""
	var hand_button_node: Node = node.get_node_or_null("CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1")
	if hand_button_node is Button:
		gem_producer_button_text = (hand_button_node as Button).text
	var advanced_button_before_focus: Button = _find_hand_button(hud, "gem_offset_consume_ruby_fail")
	var advanced_disabled_before_focus: bool = false
	var advanced_tooltip_before_focus: String = ""
	if advanced_button_before_focus != null:
		advanced_disabled_before_focus = advanced_button_before_focus.disabled
		advanced_tooltip_before_focus = advanced_button_before_focus.tooltip_text

	node.call("player_play_card", "gem_produce_ruby_a")
	node.call("player_play_card", "gem_produce_sapphire_a")
	var failed_play_result: Dictionary = node.call("player_play_card", "gem_offset_consume_ruby_fail")
	var vm_after_fail: Dictionary = node.call("get_view_model")
	var event_stream_after_fail: Array = node.get("event_stream")
	var focus_gate_reason: String = _find_play_reject_reason(event_stream_after_fail, "gem_offset_consume_ruby_fail")

	node.call("player_play_card", "gem_focus_a")
	var vm_after_focus: Dictionary = node.call("get_view_model")
	var focus_after_focus_card: int = int(vm_after_focus.get("focus", -1))
	var advanced_button_after_focus: Button = _find_hand_button(hud, "gem_offset_consume_ruby_fail")
	var advanced_disabled_after_focus: bool = false
	var advanced_tooltip_after_focus: String = ""
	if advanced_button_after_focus != null:
		advanced_disabled_after_focus = advanced_button_after_focus.disabled
		advanced_tooltip_after_focus = advanced_button_after_focus.tooltip_text

	node.call("player_play_card", "gem_offset_consume_ruby_ok")
	var vm_after_consume: Dictionary = node.call("get_view_model")

	var advanced_event_line: String = ""
	var recent_events: Array = vm_after_consume.get("recent_events", [])
	for line in recent_events:
		var rendered: String = str(line)
		if rendered.find("gem_offset_consume_ruby_ok") >= 0:
			advanced_event_line = rendered
			break

	var zones_text: String = ""
	var zones_label_node: Node = node.get_node_or_null("CombatHud/Margin/VBox/StatsRow/ZonesPanel/Zones")
	if zones_label_node is Label:
		zones_text = (zones_label_node as Label).text

	var payload: Dictionary = {
		"failed_play_ok": bool(failed_play_result.get("ok", false)),
		"focus_gate_reason": focus_gate_reason,
		"focus_gate_result_reason": str(failed_play_result.get("reason", "")),
		"advanced_disabled_before_focus": advanced_disabled_before_focus,
		"advanced_tooltip_before_focus": advanced_tooltip_before_focus,
		"hand_after_failed_play": vm_after_fail.get("hand", []).duplicate(true),
		"focus_after_failed_play": int(vm_after_fail.get("focus", -1)),
		"stack_after_failed_play": vm_after_fail.get("gem_stack", []).duplicate(true),
		"focus_after_focus_card": focus_after_focus_card,
		"advanced_disabled_after_focus": advanced_disabled_after_focus,
		"advanced_tooltip_after_focus": advanced_tooltip_after_focus,
		"focus_after_advanced_consume": int(vm_after_consume.get("focus", -1)),
		"stack_after_advanced_consume": vm_after_consume.get("gem_stack", []),
		"vm_stack_top": vm_after_consume.get("gem_stack_top", []),
		"zones_text": zones_text,
		"advanced_event_line": advanced_event_line,
		"gem_producer_button_text": gem_producer_button_text,
	}

	print("GSM_INTEGRATION_PROBE=" + JSON.stringify(payload))
	quit()
