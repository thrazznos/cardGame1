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
	var energy: int = int(view_model.get("energy", 0))
	var play_gate_reason: String = str(view_model.get("play_gate_reason", ""))
	if energy <= 0 or play_gate_reason != "" or hand.is_empty():
		return {"type": "pass"}

	var best_card_id: String = ""
	var best_score: float = -INF
	for card in hand:
		var card_id: String = str(card)
		var score: float = _score_card(card_id, view_model)
		if score > best_score:
			best_score = score
			best_card_id = card_id
		elif score == best_score and card_id < best_card_id:
			best_card_id = card_id

	if best_card_id == "":
		return {"type": "pass"}
	return {
		"type": "play",
		"card_id": best_card_id,
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
