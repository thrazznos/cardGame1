extends SceneTree

func _vm(recent_events: Array) -> Dictionary:
	return {
		"turn": 2,
		"ui_phase_text": "Player Turn",
		"combat_result": "in_progress",
		"encounter_index": 1,
		"encounter_title": "Encounter 1 • Ambush Patrol",
		"encounter_intent_style": "Steady Pressure",
		"encounter_intro_flavor": "Scout whistles echo through the corridor.",
		"pressure_profile_name": "Steady Pressure",
		"enemy_intent": {"intent_type": "attack", "damage": 6, "telegraph_text": "Attack for 6"},
		"player_hp": 34,
		"player_max_hp": 40,
		"player_block": 2,
		"enemy_hp": 18,
		"enemy_max_hp": 24,
		"enemy_block": 0,
		"energy": 2,
		"turn_energy_max": 3,
		"zones": {"draw": 4, "discard": 1, "exhaust": 0, "limbo": 0},
		"queue_preview": [],
		"last_resolved_queue_item": {},
		"play_gate_reason": "",
		"pass_gate_reason": "",
		"last_reject_reason": "ERR_NO_VALID_TARGETS",
		"recent_events": recent_events,
		"hand": ["defend_01", "scheme_flow"],
		"player_statuses": [],
		"enemy_statuses": [],
		"reward_state": "none",
		"reward_offer": [],
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	}

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_stage.tscn")
	var root_node: Control = scene.instantiate()
	root.add_child(root_node)
	await process_frame
	root_node.set_deferred("size", Vector2(1280, 720))
	await process_frame
	await process_frame

	var runner: Node = root_node
	var hud: Node = root_node.get_node("CombatHud")
	if hud is Control:
		(hud as Control).set_deferred("size", Vector2(1280, 720))
		await process_frame

	var resolve_line: String = str(runner.call("_format_event_line", {
		"order_index": 9,
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
		"order_index": 10,
		"kind": "reward_offer",
		"payload": {"offer_card_ids": ["strike_plus", "gem_focus", "defend_plus"]},
	}))
	var reject_line: String = str(runner.call("_format_event_line", {
		"order_index": 11,
		"kind": "play_reject",
		"payload": {"card_id": "strike", "reason": "ERR_NO_VALID_TARGETS"},
	}))
	var reward_reject_line: String = str(runner.call("_format_event_line", {
		"order_index": 12,
		"kind": "reward_reject",
		"payload": {"card_id": "defend_plus", "reason": "ERR_REWARD_NOT_AVAILABLE"},
	}))

	hud.call("refresh", _vm([resolve_line, reward_line, reject_line]))
	await process_frame
	await process_frame

	var payload: Dictionary = hud.call("_debug_event_feed_snapshot")
	payload["reward_reject_text"] = reward_reject_line
	payload["reward_reject_tone"] = str(hud.call("_event_feed_tone", reward_reject_line))
	print("COMBAT_STAGE_EVENT_FEED_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
