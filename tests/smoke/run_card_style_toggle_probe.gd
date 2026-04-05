extends SceneTree

class FakeRunner:
	extends RefCounted
	func player_play_card(_card_id: String) -> Dictionary:
		return {"ok": true}
	func player_pass() -> Dictionary:
		return {"ok": true}
	func choose_reward_by_index(_offer_index: int) -> Dictionary:
		return {"ok": true}
	func start_next_encounter() -> void:
		pass


func _press_key(hud: Node, keycode: Key) -> void:
	if not hud.has_method("_unhandled_input"):
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = keycode
	hud.call("_unhandled_input", event)


func _vm(hand: Array) -> Dictionary:
	return {
		"turn": 1,
		"ui_phase_text": "Player Turn",
		"combat_result": "in_progress",
		"encounter_index": 1,
		"encounter_title": "Encounter 1 • Ambush Patrol",
		"encounter_intent_style": "Steady pressure",
		"encounter_intro_flavor": "Scout whistles echo through the corridor.",
		"player_hp": 40,
		"player_max_hp": 40,
		"player_block": 0,
		"enemy_hp": 24,
		"enemy_max_hp": 24,
		"enemy_block": 0,
		"enemy_intent_damage": 6,
		"energy": 3,
		"turn_energy_max": 3,
		"zones": {"draw": 5, "discard": 0, "exhaust": 0, "limbo": 0},
		"queue_preview": [],
		"last_resolved_queue_item": {},
		"play_gate_reason": "",
		"pass_gate_reason": "",
		"last_reject_reason": "",
		"recent_events": ["Battle ready"],
		"hand": hand,
		"reward_state": "none",
		"reward_offer": [],
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	}


func _card1_bg_color(hud: Node) -> String:
	var button_node: Node = hud.get_node("Margin/VBox/HandPanel/HandVBox/HandButtons/Card1")
	if not (button_node is Button):
		return ""
	var button: Button = button_node
	var style: StyleBox = button.get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		return (style as StyleBoxFlat).bg_color.to_html(true)
	return ""


func _hand_label(hud: Node) -> String:
	var node: Node = hud.get_node("Margin/VBox/HandPanel/HandVBox/Hand")
	if node is Label:
		return (node as Label).text
	return ""


func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	var fake_runner := FakeRunner.new()
	hud.call("bind_runner", fake_runner)
	hud.call("refresh", _vm(["strike_01", "defend_01", "scheme_flow"]))
	await process_frame

	var classic_bg_color: String = _card1_bg_color(hud)
	var classic_label: String = _hand_label(hud)

	_press_key(hud, KEY_V)
	await process_frame
	var alt_bg_color: String = _card1_bg_color(hud)
	var alt_label: String = _hand_label(hud)
	var style_after_first_toggle: String = str(hud.get("card_style_variant"))

	_press_key(hud, KEY_V)
	await process_frame
	var classic_again_bg_color: String = _card1_bg_color(hud)
	var style_after_second_toggle: String = str(hud.get("card_style_variant"))

	var payload: Dictionary = {
		"classic_bg_color": classic_bg_color,
		"alt_bg_color": alt_bg_color,
		"classic_again_bg_color": classic_again_bg_color,
		"classic_label": classic_label,
		"alt_label": alt_label,
		"style_after_first_toggle": style_after_first_toggle,
		"style_after_second_toggle": style_after_second_toggle,
	}
	print("CARD_STYLE_TOGGLE_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
