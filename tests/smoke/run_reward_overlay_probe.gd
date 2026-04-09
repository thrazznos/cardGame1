extends SceneTree

func _label_text(node: Node) -> String:
	if node is Label:
		return (node as Label).text
	return ""

func _has_texture(node: Node) -> bool:
	return node is TextureRect and (node as TextureRect).texture != null

func _footer_text(node: Node) -> String:
	if not (node is Button):
		return ""
	var footer_node: Node = (node as Button).get_node_or_null("FooterLabel")
	return _label_text(footer_node)

func _is_disabled(node: Node) -> bool:
	return node is Button and (node as Button).disabled

func _visible_reward_count(node: Node) -> int:
	if not (node is HBoxContainer):
		return 0
	var count: int = 0
	for child in (node as HBoxContainer).get_children():
		if child is CanvasItem and (child as CanvasItem).visible:
			count += 1
	return count

func _vm(reward_state: String, reward_selected_card_id: String = "", reward_summary_text: String = "") -> Dictionary:
	return {
		"turn": 1,
		"ui_phase_text": "Player Turn",
		"combat_result": "player_win" if reward_state != "none" else "in_progress",
		"encounter_index": 1,
		"encounter_title": "Encounter 1 • Ambush Patrol",
		"encounter_intent_style": "Steady pressure",
		"encounter_intro_flavor": "Scout whistles echo through the corridor.",
		"player_hp": 40,
		"player_max_hp": 40,
		"player_block": 0,
		"enemy_hp": 0 if reward_state != "none" else 24,
		"enemy_max_hp": 24,
		"enemy_block": 0,
		"enemy_intent_damage": 0,
		"energy": 3,
		"turn_energy_max": 3,
		"zones": {"draw": 5, "discard": 0, "exhaust": 0, "limbo": 0},
		"queue_preview": [],
		"last_resolved_queue_item": {},
		"play_gate_reason": "",
		"pass_gate_reason": "",
		"last_reject_reason": "",
		"recent_events": ["Victory secured"],
		"hand": ["strike_01", "defend_01"],
		"reward_state": reward_state,
		"reward_offer": [
			{"card_id": "strike_plus"},
			{"card_id": "gem_focus"},
			{"card_id": "defend_plus"},
		],
		"reward_selected_card_id": reward_selected_card_id,
		"reward_summary_text": reward_summary_text,
	}

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var hud: Node = root_node.get_node("CombatHud")
	var overlay: Node = hud.get_node_or_null("RewardOverlay")
	var reward_panel: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel")
	var title_node: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardTitle")
	var subtitle_node: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSubtitle")
	var state_node: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardState")
	var choices_node: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices")
	var seal_node: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardSealRow/RewardSeal")
	var continue_node: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardContinue")
	var reward_one: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1")
	var reward_two: Node = hud.get_node_or_null("RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward2")

	hud.call("refresh", _vm("presented"))
	await process_frame
	await create_timer(0.05).timeout

	var payload: Dictionary = {
		"presented_overlay_visible": overlay is CanvasItem and (overlay as CanvasItem).visible,
		"presented_panel_min_width": int((reward_panel as Control).custom_minimum_size.x) if reward_panel is Control else 0,
		"presented_title": _label_text(title_node),
		"presented_subtitle": _label_text(subtitle_node),
		"presented_state_text": _label_text(state_node),
		"presented_visible_reward_count": _visible_reward_count(choices_node),
		"presented_seal_has_texture": _has_texture(seal_node),
		"presented_continue_visible": continue_node is CanvasItem and (continue_node as CanvasItem).visible,
		"presented_selected_footer": _footer_text(reward_two),
	}

	hud.call("refresh", _vm("applied", "gem_focus", "Reward claimed."))
	await process_frame
	await create_timer(0.05).timeout

	payload["applied_overlay_visible"] = overlay is CanvasItem and (overlay as CanvasItem).visible
	payload["applied_title"] = _label_text(title_node)
	payload["applied_subtitle"] = _label_text(subtitle_node)
	payload["applied_state_text"] = _label_text(state_node)
	payload["applied_continue_visible"] = continue_node is CanvasItem and (continue_node as CanvasItem).visible
	payload["applied_selected_footer"] = _footer_text(reward_two)
	payload["applied_unselected_footer"] = _footer_text(reward_one)
	payload["applied_selected_disabled"] = _is_disabled(reward_two)
	payload["applied_unselected_disabled"] = _is_disabled(reward_one)

	print("REWARD_OVERLAY_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
