extends RefCounted
class_name RewardDraft

const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

var card_catalog: Variant

func _init() -> void:
	card_catalog = CARD_CATALOG_SCRIPT.new()

func set_card_catalog(catalog: Variant) -> void:
	card_catalog = catalog

func build_card_offer(rng: Variant, reward_context: Dictionary, reward_history: Array = []) -> Dictionary:
	var checkpoint_id: String = _checkpoint_id_for_context(reward_context)
	var reward_pool_tag: String = _reward_pool_tag_for_context(reward_context)
	var active_unlock_key: String = _active_unlock_key_for_context(reward_context)

	var pool: Array = []
	if card_catalog != null:
		pool = card_catalog.reward_pool_entries(reward_pool_tag)

	var eligible_pool: Array[Dictionary] = []
	for entry in pool:
		if not (entry is Dictionary):
			continue
		var card: Dictionary = (entry as Dictionary).duplicate(true)
		if not _is_unlock_eligible(card, active_unlock_key):
			continue
		eligible_pool.append(card)

	var available: Array[Dictionary] = []
	for entry in eligible_pool:
		var card_id: String = str(entry.get("card_id", ""))
		if not reward_history.has(card_id):
			available.append(entry.duplicate(true))

	if available.size() < 3:
		var seen_card_ids: Dictionary = {}
		for entry in available:
			seen_card_ids[str(entry.get("card_id", ""))] = true
		for entry in eligible_pool:
			var card_id: String = str(entry.get("card_id", ""))
			if seen_card_ids.has(card_id):
				continue
			available.append(entry.duplicate(true))
			seen_card_ids[card_id] = true
			if available.size() >= 3:
				break
		if available.size() < 3:
			for entry in eligible_pool:
				available.append(entry.duplicate(true))
				if available.size() >= 3:
					break

	var cursor_start: int = int(rng.cursors.get("reward.card", 0))
	var offers: Array[Dictionary] = []
	while offers.size() < 3 and not available.is_empty():
		var draw: Dictionary = rng.draw_next("reward.card")
		var pick_index: int = _pick_index(int(draw.get("value", 0)), available, reward_context)
		offers.append(available.pop_at(pick_index))

	return {
		"checkpoint_id": checkpoint_id,
		"draft_instance_id": "%s_draft_%d" % [checkpoint_id, cursor_start],
		"offers": offers,
		"cursor_start": cursor_start,
	}

func _checkpoint_id_for_context(reward_context: Dictionary) -> String:
	var checkpoint_id: String = str(reward_context.get("checkpoint_id", "reward_checkpoint")).strip_edges()
	if checkpoint_id == "":
		return "reward_checkpoint"
	return checkpoint_id

func _reward_pool_tag_for_context(reward_context: Dictionary) -> String:
	var reward_pool_tag: String = str(reward_context.get("reward_pool_tag", "base_reward")).strip_edges()
	if reward_pool_tag == "":
		return "base_reward"
	return reward_pool_tag

func _active_unlock_key_for_context(reward_context: Dictionary) -> String:
	var active_unlock_key: String = str(reward_context.get("active_unlock_key", "base_set")).strip_edges()
	if active_unlock_key == "":
		return "base_set"
	return active_unlock_key

func _is_unlock_eligible(entry: Dictionary, active_unlock_key: String) -> bool:
	return _unlock_key_for_entry(entry, active_unlock_key) == active_unlock_key

func _unlock_key_for_entry(entry: Dictionary, fallback_unlock_key: String) -> String:
	var unlock_key: String = str(entry.get("unlock_key", fallback_unlock_key)).strip_edges()
	if unlock_key == "":
		return fallback_unlock_key
	return unlock_key

func _pick_index(draw_value: int, available: Array[Dictionary], reward_context: Dictionary) -> int:
	if available.is_empty():
		return 0
	if _all_equal_weights(available, reward_context):
		return _uniform_pick_index(draw_value, available.size())
	return _weighted_pick_index(draw_value, available, reward_context)

func _uniform_pick_index(draw_value: int, size: int) -> int:
	if size <= 0:
		return 0
	return draw_value % size

func _all_equal_weights(available: Array[Dictionary], reward_context: Dictionary) -> bool:
	if available.size() < 2:
		return true
	var first_weight: float = _weight_for_entry(available[0], reward_context)
	for index in range(1, available.size()):
		if not is_equal_approx(_weight_for_entry(available[index], reward_context), first_weight):
			return false
	return true

func _weighted_pick_index(draw_value: int, available: Array[Dictionary], reward_context: Dictionary) -> int:
	var total_weight: float = 0.0
	for entry in available:
		total_weight += _weight_for_entry(entry, reward_context)
	if total_weight <= 0.0:
		return _uniform_pick_index(draw_value, available.size())

	var roll: float = fmod(float(draw_value), total_weight)
	var cumulative_weight: float = 0.0
	for index in range(available.size()):
		cumulative_weight += _weight_for_entry(available[index], reward_context)
		if roll < cumulative_weight or index == available.size() - 1:
			return index
	return 0

func _weight_for_entry(entry: Dictionary, reward_context: Dictionary) -> float:
	var base_weight: float = max(float(entry.get("weight_base", 1.0)), 0.0)
	if base_weight <= 0.0:
		return 0.0
	return base_weight * _weight_modifier_scalar(entry, reward_context)

func _weight_modifier_scalar(entry: Dictionary, reward_context: Dictionary) -> float:
	var modifiers_variant: Variant = entry.get("weight_modifiers", [])
	if not (modifiers_variant is Array):
		return 1.0
	var modifiers: Array[Dictionary] = []
	for modifier_variant in modifiers_variant:
		if not (modifier_variant is Dictionary):
			continue
		modifiers.append((modifier_variant as Dictionary).duplicate(true))
	if modifiers.is_empty():
		return 1.0
	modifiers.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.get("modifier_id", "")) < str(b.get("modifier_id", "")))
	var aggregate: float = 1.0
	for modifier in modifiers:
		if not _weight_modifier_is_active(modifier, reward_context):
			continue
		aggregate *= _weight_modifier_value(modifier)
	return clamp(aggregate, 0.5, 2.0)

func _weight_modifier_is_active(modifier: Dictionary, reward_context: Dictionary) -> bool:
	var condition_key: String = str(modifier.get("condition_key", "")).strip_edges()
	if condition_key == "":
		return true
	var active_conditions_variant: Variant = reward_context.get("weight_modifier_conditions", [])
	if not (active_conditions_variant is Array):
		return false
	for active_condition_variant in active_conditions_variant:
		if str(active_condition_variant).strip_edges() == condition_key:
			return true
	return false

func _weight_modifier_value(modifier: Dictionary) -> float:
	match str(modifier.get("type", "")).strip_edges():
		"multiply":
			return clamp(float(modifier.get("value", 1.0)), 0.5, 2.0)
		_:
			return 1.0
