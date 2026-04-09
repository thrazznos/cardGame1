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

func _vm(recent_events: Array, last_resolved_queue_item: Dictionary) -> Dictionary:
	return {
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
		"energy": 2,
		"turn_energy_max": 3,
		"zones": {"draw": 5, "discard": 1, "exhaust": 0, "limbo": 0},
		"queue_preview": [],
		"last_resolved_queue_item": last_resolved_queue_item,
		"play_gate_reason": "",
		"pass_gate_reason": "",
		"last_reject_reason": "",
		"recent_events": recent_events,
		"hand": ["defend_01", "scheme_flow"],
		"reward_state": "none",
		"reward_offer": [],
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	}

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame
	await process_frame

	var runner: Node = root_node
	var play_line: String = str(runner.call("_format_event_line", {
		"order_index": 1,
		"kind": "play_commit",
		"payload": {"card_id": "strike_01", "energy_after": 2},
	}))
	var resolve_line: String = str(runner.call("_format_event_line", {
		"order_index": 2,
		"kind": "effect_resolve",
		"payload": {
			"item": {
				"source_instance_id": "strike_01",
				"card_id": "strike",
				"timing_window_priority": 1,
				"speed_class_priority": 1,
				"enqueue_sequence_id": 0,
			},
			"result": {"ok": true},
			"effect": {"type": "deal_damage", "amount": 6},
		},
	}))
	var reward_line: String = str(runner.call("_format_event_line", {
		"order_index": 9,
		"kind": "reward_offer",
		"payload": {"offer_card_ids": ["strike_plus", "defend_plus", "strike_precise"]},
	}))
	var reject_line: String = str(runner.call("_format_event_line", {
		"order_index": 10,
		"kind": "play_reject",
		"payload": {"card_id": "gem_offset_consume_ruby_ok", "reason": "ERR_FOCUS_REQUIRED"},
	}))
	var no_target_reject_line: String = str(runner.call("_format_event_line", {
		"order_index": 11,
		"kind": "play_reject",
		"payload": {"card_id": "strike", "reason": "ERR_NO_VALID_TARGETS"},
	}))
	var stack_reject_line: String = str(runner.call("_format_event_line", {
		"order_index": 12,
		"kind": "play_reject",
		"payload": {"card_id": "probe_stack_top_anchor", "reason": "ERR_STACK_TOP_MISMATCH"},
	}))

	var hud: Node = root_node.get_node("CombatHud")
	hud.call("bind_runner", FakeRunner.new())
	hud.call("refresh", _vm([play_line, resolve_line], {
		"source_instance_id": "strike_01",
		"card_id": "strike",
		"timing_window_priority": 1,
		"speed_class_priority": 1,
		"enqueue_sequence_id": 0,
	}))
	await process_frame
	await process_frame

	var queue_label := hud.get_node("Margin/VBox/QueuePanel/Queue") as Label
	var event_label := hud.get_node("Margin/VBox/EventPanel/EventLog") as Label
	var payload: Dictionary = {
		"queue_text": queue_label.text,
		"event_log_text": event_label.text,
		"reward_line": reward_line,
		"reject_line": reject_line,
		"no_target_reject_line": no_target_reject_line,
		"stack_reject_line": stack_reject_line,
	}
	print("EVENT_READABILITY_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
