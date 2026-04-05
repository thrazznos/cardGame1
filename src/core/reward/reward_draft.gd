extends RefCounted
class_name RewardDraft

const BASE_CARD_POOL := [
	{"card_id": "strike_plus", "rarity": "common", "unlock_key": "base_set", "weight_base": 1.0},
	{"card_id": "strike_precise", "rarity": "common", "unlock_key": "base_set", "weight_base": 1.0},
	{"card_id": "defend_plus", "rarity": "common", "unlock_key": "base_set", "weight_base": 1.0},
	{"card_id": "defend_hold", "rarity": "common", "unlock_key": "base_set", "weight_base": 1.0},
	{"card_id": "scheme_flow", "rarity": "common", "unlock_key": "base_set", "weight_base": 1.0},
]

func build_card_offer(rng: Variant, checkpoint_id: String, reward_history: Array = []) -> Dictionary:
	var available: Array[Dictionary] = []
	for entry in BASE_CARD_POOL:
		var card: Dictionary = entry.duplicate(true)
		if not reward_history.has(str(card.get("card_id", ""))):
			available.append(card)

	if available.size() < 3:
		for entry in BASE_CARD_POOL:
			available.append(entry.duplicate(true))
			if available.size() >= 3:
				break

	var cursor_start: int = int(rng.cursors.get("reward.card", 0))
	var offers: Array[Dictionary] = []
	while offers.size() < 3 and not available.is_empty():
		var draw: Dictionary = rng.draw_next("reward.card")
		var pick_index: int = int(draw.get("value", 0)) % available.size()
		offers.append(available.pop_at(pick_index))

	return {
		"checkpoint_id": checkpoint_id,
		"draft_instance_id": "%s_draft_%d" % [checkpoint_id, cursor_start],
		"offers": offers,
		"cursor_start": cursor_start,
	}
