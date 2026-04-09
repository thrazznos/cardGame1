extends SceneTree

const UI_THEME := preload("res://src/ui/theme.gd")
const VIEWPORT_SIZE := Vector2(1280, 720)

func _vm() -> Dictionary:
	return {
		"turn": 1,
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
		"last_reject_reason": "",
		"recent_events": [],
		"hand": ["strike_01", "defend_01", "scheme_flow"],
		"hand_card_ids": ["strike", "defend", "scheme_flow"],
		"hand_play_reasons": ["", "", ""],
		"player_statuses": [],
		"enemy_statuses": [],
		"reward_state": "none",
		"reward_offer": [],
		"reward_selected_card_id": "",
		"reward_summary_text": "",
	}

func _hand_layout(card_count: int) -> Dictionary:
	var total_width: float = UI_THEME.CARD_WIDTH + float(card_count - 1) * UI_THEME.CARD_OVERLAP
	return {
		"start_x": (VIEWPORT_SIZE.x - total_width) / 2.0,
		"base_y": VIEWPORT_SIZE.y * 0.55 + 16.0,
	}

func _base_card_center(index: int, card_count: int) -> Vector2:
	var layout: Dictionary = _hand_layout(card_count)
	var x: float = float(layout.get("start_x", 0.0)) + float(index) * UI_THEME.CARD_OVERLAP
	var y: float = float(layout.get("base_y", 0.0))
	return Vector2(x + UI_THEME.CARD_WIDTH * 0.5, y + UI_THEME.CARD_HEIGHT * 0.5)

func _hovered_card_rect(index: int, card_count: int) -> Rect2:
	var layout: Dictionary = _hand_layout(card_count)
	var width: float = UI_THEME.CARD_WIDTH * UI_THEME.CARD_HOVER_SCALE
	var height: float = UI_THEME.CARD_HEIGHT * UI_THEME.CARD_HOVER_SCALE
	var x: float = float(layout.get("start_x", 0.0)) + float(index) * UI_THEME.CARD_OVERLAP
	var y: float = float(layout.get("base_y", 0.0)) - UI_THEME.CARD_HOVER_LIFT
	x -= (width - UI_THEME.CARD_WIDTH) * 0.5
	y -= (height - UI_THEME.CARD_HEIGHT)
	return Rect2(Vector2(x, y), Vector2(width, height))

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

	var card_count: int = 3
	var payload: Dictionary = {
		"base_first": int(stage.call("_card_at_position", _base_card_center(0, card_count))),
		"base_second": int(stage.call("_card_at_position", _base_card_center(1, card_count))),
		"base_third": int(stage.call("_card_at_position", _base_card_center(2, card_count))),
	}

	stage.set("hovered_card_index", 1)
	await process_frame
	var hovered_rect: Rect2 = _hovered_card_rect(1, card_count)
	payload["hovered_extension_hit"] = int(stage.call("_card_at_position", hovered_rect.position + Vector2(12.0, 12.0)))
	payload["hovered_above_miss"] = int(stage.call("_card_at_position", hovered_rect.position + Vector2(hovered_rect.size.x * 0.5, -8.0)))

	print("COMBAT_STAGE_HAND_HIT_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
