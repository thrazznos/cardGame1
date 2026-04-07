extends SceneTree

class FakeRunner:
	extends RefCounted
	var pass_calls: int = 0
	func player_pass() -> Dictionary:
		pass_calls += 1
		return {"ok": true}
	func player_play_card(_card_id: String) -> Dictionary:
		return {"ok": true}
	func choose_reward_by_index(_offer_index: int) -> Dictionary:
		return {"ok": true}
	func start_next_encounter() -> void:
		pass


func _vm(hand: Array) -> Dictionary:
	return {
		"turn": 1,
		"ui_phase_text": "Player Turn",
		"combat_result": "in_progress",
		"encounter_index": 2,
		"encounter_title": "Encounter 2 • Warden Counterpush",
		"encounter_intent_style": "Burst Charger",
		"encounter_intro_flavor": "Heavy boots thunder as the warden rushes in.",
		"pressure_profile_id": "burst",
		"pressure_profile_name": "Burst Charger",
		"enemy_intent": {"intent_type": "charge", "damage": 1, "telegraph_text": "Charging up... (+4 block)", "block_gain": 4},
		"player_hp": 40,
		"player_max_hp": 40,
		"player_block": 0,
		"enemy_hp": 28,
		"enemy_max_hp": 28,
		"enemy_block": 0,
		"enemy_intent_damage": 1,
		"energy": 3,
		"turn_energy_max": 3,
		"zones": {"draw": 5, "discard": 0, "exhaust": 0, "limbo": 0},
		"queue_preview": [],
		"last_resolved_queue_item": {},
		"play_gate_reason": "",
		"pass_gate_reason": "",
		"last_reject_reason": "",
		"recent_events": ["Encounter begins"],
		"hand": hand,
		"reward_state": "none",
		"reward_offer": [],
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	}


func _press_enter(hud: Node) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.echo = false
	event.keycode = KEY_ENTER
	hud.call("_unhandled_input", event)


func _toast_visible(hud: Node) -> bool:
	var layer_node: Node = hud.get_node("TransitionToastLayer")
	if layer_node is Control:
		return (layer_node as Control).visible
	return false


func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	var fake_runner := FakeRunner.new()
	hud.call("bind_runner", fake_runner)

	# Seed previous_vm with encounter 1 so refresh to encounter 2 triggers toast.
	hud.call("refresh", {
		"turn": 1,
		"ui_phase_text": "Player Turn",
		"combat_result": "in_progress",
		"encounter_index": 1,
		"encounter_title": "Encounter 1 • Ambush Patrol",
		"encounter_intent_style": "Steady Pressure",
		"encounter_intro_flavor": "Scout whistles echo through the corridor.",
		"pressure_profile_id": "steady",
		"pressure_profile_name": "Steady Pressure",
		"enemy_intent": {"intent_type": "attack", "damage": 6, "telegraph_text": "Attack for 6"},
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
		"hand": ["strike_01", "defend_01"],
		"reward_state": "none",
		"reward_offer": [],
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	})
	await process_frame

	hud.call("refresh", _vm(["strike_01", "defend_01"]))
	await process_frame

	var visible_immediately: bool = _toast_visible(hud)
	var pass_calls_while_visible: int = fake_runner.pass_calls

	await create_timer(0.85).timeout
	var visible_after_auto_delay: bool = _toast_visible(hud)

	_press_enter(hud)
	await process_frame
	var visible_after_enter: bool = _toast_visible(hud)
	var pass_calls_after_auto_dismiss: int = fake_runner.pass_calls

	var payload: Dictionary = {
		"visible_immediately": visible_immediately,
		"visible_after_auto_delay": visible_after_auto_delay,
		"visible_after_enter": visible_after_enter,
		"pass_calls_while_visible": pass_calls_while_visible,
		"pass_calls_after_auto_dismiss": pass_calls_after_auto_dismiss,
	}
	print("ENCOUNTER_TOAST_PROBE=" + JSON.stringify(payload))

	root_node.queue_free()
	await process_frame
	quit()
