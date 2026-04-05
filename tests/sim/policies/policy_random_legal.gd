extends RefCounted

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

	# Deterministic pseudo-random index from current visible state.
	var turn_index: int = int(view_model.get("turn", 1))
	var pick_index: int = int((turn_index * 31 + energy * 17 + hand.size() * 13) % hand.size())
	return {
		"type": "play",
		"card_id": str(hand[pick_index]),
	}
