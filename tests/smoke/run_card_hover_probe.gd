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

func _vector_payload(value: Vector2) -> Dictionary:
	return {"x": snappedf(value.x, 0.01), "y": snappedf(value.y, 0.01)}

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	hud.call("bind_runner", FakeRunner.new())
	hud.call("refresh", _vm(["strike_01", "defend_01", "scheme_flow"]))
	await process_frame

	var button_node: Node = hud.get_node("Margin/VBox/HandPanel/HandVBox/HandButtons/Card1")
	var payload: Dictionary = {}
	if button_node is Button:
		var button: Button = button_node
		payload["scale_before"] = _vector_payload(button.scale)
		payload["z_before"] = button.z_index
		button.emit_signal("mouse_entered")
		await create_timer(0.16).timeout
		payload["scale_hover"] = _vector_payload(button.scale)
		payload["z_hover"] = button.z_index
		button.emit_signal("mouse_exited")
		await create_timer(0.16).timeout
		payload["scale_after"] = _vector_payload(button.scale)
		payload["z_after"] = button.z_index
	print("CARD_HOVER_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
