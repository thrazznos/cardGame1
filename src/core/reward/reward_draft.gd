extends RefCounted
class_name RewardDraft

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

var card_catalog: Variant

func _init() -> void:
	card_catalog = CARD_CATALOG_SCRIPT.new()

func set_card_catalog(catalog: Variant) -> void:
	card_catalog = catalog

func build_card_offer(rng: Variant, checkpoint_id: String, reward_history: Array = []) -> Dictionary:
	var pool: Array = []
	if card_catalog != null:
		pool = card_catalog.reward_pool_entries(checkpoint_id)

	var available: Array[Dictionary] = []
	for entry in pool:
		var card: Dictionary = entry.duplicate(true)
		if not reward_history.has(str(card.get("card_id", ""))):
			available.append(card)

	if available.size() < 3:
		for entry in pool:
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
