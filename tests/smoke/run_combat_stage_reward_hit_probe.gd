extends SceneTree

const VIEWPORT_SIZE := Vector2(1280, 720)
const CARD_W := 308.0
const CARD_H := 418.0
const CARD_GAP := 24.0
const CARD_Y := 188.0
const CARD_HOVER_LIFT := 14.0

func _vm() -> Dictionary:
	return {
		"turn": 2,
		"ui_phase_text": "Victory",
		"combat_result": "player_win",
		"encounter_index": 1,
		"encounter_title": "Encounter 1 • Ambush Patrol",
		"encounter_intent_style": "Steady Pressure",
		"encounter_intro_flavor": "Scout whistles echo through the corridor.",
		"pressure_profile_name": "Steady Pressure",
		"enemy_intent": {"intent_type": "attack", "damage": 0, "telegraph_text": "Defeated"},
		"player_hp": 34,
		"player_max_hp": 40,
		"player_block": 2,
		"enemy_hp": 0,
		"enemy_max_hp": 24,
		"enemy_block": 0,
		"energy": 2,
		"turn_energy_max": 3,
		"zones": {"draw": 4, "discard": 1, "exhaust": 0, "limbo": 0},
		"queue_preview": [],
		"last_resolved_queue_item": {},
		"play_gate_reason": "",
		"pass_gate_reason": "",
		"last_reject_reason": "",
		"recent_events": ["Victory secured"],
		"hand": [],
		"player_statuses": [],
		"enemy_statuses": [],
		"reward_state": "presented",
		"reward_offer": [
			{"card_id": "strike_plus"},
			{"card_id": "gem_focus"},
			{"card_id": "defend_plus"},
		],
		"reward_selected_card_id": "",
		"reward_summary_text": "Hover a card for a closer look, then click to draft it.",
	}

func _layout_start_x() -> float:
	var total_w: float = 3.0 * CARD_W + 2.0 * CARD_GAP
	return (VIEWPORT_SIZE.x - total_w) / 2.0

func _card_center(index: int) -> Vector2:
	var x: float = _layout_start_x() + float(index) * (CARD_W + CARD_GAP)
	return Vector2(x + CARD_W * 0.5, CARD_Y + CARD_H * 0.5)

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_stage.tscn")
	var root_node: Control = scene.instantiate()
	root.add_child(root_node)
	await process_frame
	root_node.set_deferred("size", VIEWPORT_SIZE)
	var stage: Control = root_node.get_node("CombatHud")
	stage.set_deferred("size", VIEWPORT_SIZE)
	await process_frame
	await process_frame

	stage.call("refresh", _vm())
	await process_frame
	await process_frame

	var payload: Dictionary = {
		"hit_first": int(stage.call("_reward_card_at_position", _card_center(0))),
		"hit_second": int(stage.call("_reward_card_at_position", _card_center(1))),
		"hit_third": int(stage.call("_reward_card_at_position", _card_center(2))),
		"gap_between_cards": int(stage.call("_reward_card_at_position", Vector2(_layout_start_x() + CARD_W + CARD_GAP * 0.5, CARD_Y + CARD_H * 0.5))),
		"space_above_first": int(stage.call("_reward_card_at_position", Vector2(_layout_start_x() + CARD_W * 0.5, CARD_Y - 20.0))),
	}

	stage.set("_reward_hover_index", 1)
	await process_frame
	payload["hover_lift_second"] = int(stage.call("_reward_card_at_position", Vector2(_card_center(1).x, CARD_Y - 8.0)))
	payload["hover_lift_above_range"] = int(stage.call("_reward_card_at_position", Vector2(_card_center(1).x, CARD_Y - CARD_HOVER_LIFT - 20.0)))

	print("COMBAT_STAGE_REWARD_HIT_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
