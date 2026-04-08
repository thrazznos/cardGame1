extends RefCounted

const POLICY_ID := "greedy_value"

func get_policy_id() -> String:
	return POLICY_ID

func choose_action(view_model: Dictionary) -> Dictionary:
	if bool(view_model.get("resolve_lock", false)):
		return {"type": "pass"}
	if str(view_model.get("combat_result", "in_progress")) != "in_progress":
		return {"type": "pass"}

	var hand: Array = view_model.get("hand", [])
	var hand_card_ids: Array = view_model.get("hand_card_ids", [])
	var energy: int = int(view_model.get("energy", 0))
	var play_gate_reason: String = str(view_model.get("play_gate_reason", ""))
	if energy <= 0 or play_gate_reason != "" or hand.is_empty():
		return {"type": "pass"}

	var best_action_token: String = ""
	var best_score: float = -INF
	for index in range(hand.size()):
		var action_token: String = str(hand[index])
		var card_id: String = action_token
		if index >= 0 and index < hand_card_ids.size():
			card_id = str(hand_card_ids[index])
		var score: float = _score_card(card_id, view_model)
		if score > best_score:
			best_score = score
			best_action_token = action_token
		elif score == best_score and action_token < best_action_token:
			best_action_token = action_token

	if best_action_token == "":
		return {"type": "pass"}
	return {
		"type": "play",
		"card_id": best_action_token,
	}

func _score_card(card_id: String, view_model: Dictionary) -> float:
	var enemy_hp: int = int(view_model.get("enemy_hp", 0))
	var player_block: int = int(view_model.get("player_block", 0))
	var enemy_intent_damage: int = int(view_model.get("enemy_intent_damage", 0))

	if card_id.begins_with("strike"):
		var lethal_bonus: float = 0.0
		if enemy_hp <= 8:
			lethal_bonus = 10.0
		return 8.0 + lethal_bonus
	if card_id.begins_with("defend"):
		var pressure_bonus: float = 0.0
		if enemy_intent_damage > player_block:
			pressure_bonus = 2.0
		return 6.0 + pressure_bonus
	if card_id.begins_with("scheme"):
		return 5.0
	return 1.0
