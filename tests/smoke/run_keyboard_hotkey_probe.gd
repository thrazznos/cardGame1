extends SceneTree

class FakeRunner:
	extends RefCounted
	var played_card_ids: Array = []
	var pass_calls: int = 0
	var reward_pick_indices: Array = []
	var reward_continue_calls: int = 0

	func player_play_card(card_id: String) -> Dictionary:
		played_card_ids.append(card_id)
		return {"ok": true}

	func player_pass() -> Dictionary:
		pass_calls += 1
		return {"ok": true}

	func choose_reward_by_index(offer_index: int) -> Dictionary:
		reward_pick_indices.append(offer_index)
		return {"ok": true}

	func start_next_encounter() -> void:
		reward_continue_calls += 1


func _press_key(hud: Node, keycode: Key) -> void:
	if not hud.has_method("_unhandled_input"):
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = keycode
	hud.call("_unhandled_input", event)


func _vm(hand: Array, reward_state: String = "none", reward_offer: Array = []) -> Dictionary:
	return {
		"turn": 1,
		"ui_phase_text": "Player Turn",
		"combat_result": "in_progress",
		"encounter_index": 1,
		"encounter_title": "Encounter 1 • Ambush Patrol",
		"encounter_intent_style": "Steady pressure",
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
		"reward_state": reward_state,
		"reward_offer": reward_offer,
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	}


func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	var fake_runner := FakeRunner.new()
	hud.call("bind_runner", fake_runner)

	hud.call("refresh", _vm(["strike_01", "defend_01", "scheme_flow"]))
	_press_key(hud, KEY_2)
	_press_key(hud, KEY_ENTER)

	hud.call("refresh", _vm(["strike_01", "defend_01", "scheme_flow"], "presented", [
		{"card_id": "strike_99"},
		{"card_id": "defend_99"},
		{"card_id": "scheme_flow"},
	]))
	_press_key(hud, KEY_2)

	hud.call("refresh", _vm(["strike_01", "defend_01", "scheme_flow"], "applied", [
		{"card_id": "strike_99"},
		{"card_id": "defend_99"},
		{"card_id": "scheme_flow"},
	]))
	_press_key(hud, KEY_ENTER)
	await create_timer(0.2).timeout

	var hand_label_node: Node = hud.get_node("Margin/VBox/HandPanel/HandVBox/Hand")
	var hand_label_text: String = ""
	if hand_label_node is Label:
		hand_label_text = hand_label_node.text

	var payload: Dictionary = {
		"has_unhandled_input": hud.has_method("_unhandled_input"),
		"played_card_id": fake_runner.played_card_ids[0] if fake_runner.played_card_ids.size() > 0 else "",
		"pass_calls": fake_runner.pass_calls,
		"reward_pick_index": fake_runner.reward_pick_indices[0] if fake_runner.reward_pick_indices.size() > 0 else -1,
		"reward_continue_calls": fake_runner.reward_continue_calls,
		"hand_hotkey_label": hand_label_text,
	}
	print("KEYBOARD_HOTKEY_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
