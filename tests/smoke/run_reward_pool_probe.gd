extends SceneTree

const REWARD_DRAFT_SCRIPT := preload("res://src/core/reward/reward_draft.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")
const CARD_CATALOG_SCRIPT := preload("res://src/core/card/card_catalog.gd")

class StubCatalog:
	extends RefCounted

	var _entries: Array = []

	func _init(entries: Array = []) -> void:
		_entries = entries.duplicate(true)

	func reward_pool_entries(_reward_pool_tag: String) -> Array:
		return _entries.duplicate(true)

class StubRng:
	extends RefCounted

	var cursors: Dictionary = {}
	var _stream_values: Array = []

	func _init(stream_values: Array = [], initial_cursor: int = 0) -> void:
		cursors = {"reward.card": initial_cursor}
		_stream_values = stream_values.duplicate(true)

	func draw_next(stream_key: String) -> Dictionary:
		var draw_index: int = int(cursors.get(stream_key, 0))
		var value: int = 0
		if draw_index < _stream_values.size():
			value = int(_stream_values[draw_index])
		cursors[stream_key] = draw_index + 1
		return {
			"stream_key": stream_key,
			"draw_index": draw_index,
			"value": value,
		}

func _any_gsm(cards: Array) -> bool:
	for card_id in cards:
		if str(card_id).begins_with("gem_"):
			return true
	return false

func _all_gsm(cards: Array) -> bool:
	if cards.is_empty():
		return false
	for card_id in cards:
		if not str(card_id).begins_with("gem_"):
			return false
	return true

func _extract_ids(offers: Array) -> Array:
	var ids: Array = []
	for offer in offers:
		ids.append(str((offer as Dictionary).get("card_id", "")))
	return ids

func _all_prefixed(cards: Array, prefix: String) -> bool:
	if cards.is_empty():
		return false
	for card_id in cards:
		if not str(card_id).begins_with(prefix):
			return false
	return true

func _reward_context(checkpoint_id: String, reward_pool_tag: String, active_unlock_key: String, weight_modifier_conditions: Array = []) -> Dictionary:
	return {
		"checkpoint_id": checkpoint_id,
		"reward_pool_tag": reward_pool_tag,
		"active_unlock_key": active_unlock_key,
		"weight_modifier_conditions": weight_modifier_conditions.duplicate(true),
	}

func _run_offer_with_entries(entries: Array, reward_context: Dictionary, stream_values: Array) -> Array:
	var draft = REWARD_DRAFT_SCRIPT.new()
	draft.set_card_catalog(StubCatalog.new(entries))
	var offer: Dictionary = draft.build_card_offer(StubRng.new(stream_values), reward_context, [])
	return _extract_ids(offer.get("offers", []))

func _run_offer_with_catalog(catalog: Variant, reward_context: Dictionary, stream_values: Array) -> Array:
	var draft = REWARD_DRAFT_SCRIPT.new()
	draft.set_card_catalog(catalog)
	var offer: Dictionary = draft.build_card_offer(StubRng.new(stream_values), reward_context, [])
	return _extract_ids(offer.get("offers", []))

func _init() -> void:
	var draft = REWARD_DRAFT_SCRIPT.new()
	var rng_normal = RSGC_SCRIPT.new()
	rng_normal.bootstrap(1337)

	var history_all_base: Array = ["strike_plus", "strike_precise", "defend_plus", "defend_hold", "scheme_flow"]

	var normal_offer: Dictionary = draft.build_card_offer(rng_normal, _reward_context("shared_checkpoint_1", "base_reward", "base_set"), history_all_base)
	var normal_ids: Array = _extract_ids(normal_offer.get("offers", []))

	var rng_gsm = RSGC_SCRIPT.new()
	rng_gsm.bootstrap(1337)
	var gsm_offer: Dictionary = draft.build_card_offer(rng_gsm, _reward_context("shared_checkpoint_1", "gsm_reward", "gsm_set"), history_all_base)
	var gsm_ids: Array = _extract_ids(gsm_offer.get("offers", []))

	var mixed_entries: Array = [
		{"card_id": "gsm_alpha", "unlock_key": "gsm_set", "weight_base": 1.0},
		{"card_id": "base_alpha", "unlock_key": "base_set", "weight_base": 1.0},
		{"card_id": "gsm_beta", "unlock_key": "gsm_set", "weight_base": 1.0},
		{"card_id": "base_beta", "unlock_key": "base_set", "weight_base": 1.0},
	]
	var mixed_normal_ids: Array = _run_offer_with_entries(mixed_entries, _reward_context("shared_mixed_probe", "base_reward", "base_set"), [2, 1, 0])
	var mixed_gsm_ids: Array = _run_offer_with_entries(mixed_entries, _reward_context("shared_mixed_probe", "gsm_reward", "gsm_set"), [1, 0, 0])

	var weighted_entries: Array = [
		{"card_id": "weighted_heavy", "unlock_key": "base_set", "weight_base": 3.0},
		{"card_id": "weighted_light_a", "unlock_key": "base_set", "weight_base": 1.0},
		{"card_id": "weighted_light_b", "unlock_key": "base_set", "weight_base": 1.0},
	]
	var weighted_ids: Array = _run_offer_with_entries(weighted_entries, _reward_context("shared_weighted_probe", "base_reward", "base_set"), [2, 0, 0])

	var modifier_entries: Array = [
		{"card_id": "mod_heavy", "unlock_key": "base_set", "weight_base": 1.0, "weight_modifiers": [{"modifier_id": "boost_cap", "type": "multiply", "value": 10.0}]},
		{"card_id": "mod_light", "unlock_key": "base_set", "weight_base": 1.0, "weight_modifiers": [{"modifier_id": "trim_floor", "type": "multiply", "value": 0.1}]},
		{"card_id": "mod_plain", "unlock_key": "base_set", "weight_base": 1.0, "weight_modifiers": []},
	]
	var modifier_weight_ids: Array = _run_offer_with_entries(modifier_entries, _reward_context("shared_modifier_probe", "base_reward", "base_set"), [1, 0, 0])

	var conditional_entries: Array = [
		{"card_id": "cond_boost", "unlock_key": "base_set", "weight_base": 1.0, "weight_modifiers": [{"modifier_id": "focus_bonus", "type": "multiply", "value": 2.0, "condition_key": "focus_family"}]},
		{"card_id": "cond_plain_a", "unlock_key": "base_set", "weight_base": 1.0, "weight_modifiers": []},
		{"card_id": "cond_plain_b", "unlock_key": "base_set", "weight_base": 1.0, "weight_modifiers": []},
	]
	var conditional_inactive_ids: Array = _run_offer_with_entries(conditional_entries, _reward_context("shared_condition_probe", "base_reward", "base_set"), [1, 0, 0])
	var conditional_active_ids: Array = _run_offer_with_entries(conditional_entries, _reward_context("shared_condition_probe", "base_reward", "base_set", ["focus_family"]), [1, 0, 0])

	var live_catalog = CARD_CATALOG_SCRIPT.new()
	var real_catalog_modifier_inactive_ids: Array = _run_offer_with_catalog(live_catalog, _reward_context("real_modifier_probe", "test_reward_weight_mod", "base_set"), [1, 0, 0])
	var real_catalog_modifier_active_ids: Array = _run_offer_with_catalog(live_catalog, _reward_context("real_modifier_probe", "test_reward_weight_mod", "base_set", ["focus_family"]), [1, 0, 0])

	var equal_weight_entries: Array = [
		{"card_id": "equal_a", "unlock_key": "base_set", "weight_base": 2.0},
		{"card_id": "equal_b", "unlock_key": "base_set", "weight_base": 2.0},
		{"card_id": "equal_c", "unlock_key": "base_set", "weight_base": 2.0},
	]
	var equal_weight_ids: Array = _run_offer_with_entries(equal_weight_entries, _reward_context("shared_equal_probe", "base_reward", "base_set"), [5, 0, 0])

	var history_entries: Array = [
		{"card_id": "history_a", "unlock_key": "base_set", "weight_base": 1.0},
		{"card_id": "history_b", "unlock_key": "base_set", "weight_base": 1.0},
		{"card_id": "history_c", "unlock_key": "base_set", "weight_base": 1.0},
	]
	var history_draft = REWARD_DRAFT_SCRIPT.new()
	history_draft.set_card_catalog(StubCatalog.new(history_entries))
	var history_offer: Dictionary = history_draft.build_card_offer(StubRng.new([0, 0, 0]), _reward_context("shared_history_probe", "base_reward", "base_set"), ["history_c"])
	var history_refill_ids: Array = _extract_ids(history_offer.get("offers", []))

	var payload: Dictionary = {
		"normal_ids": normal_ids,
		"gsm_ids": gsm_ids,
		"normal_has_gsm": _any_gsm(normal_ids),
		"gsm_all_are_gsm": _all_gsm(gsm_ids),
		"mixed_normal_ids": mixed_normal_ids,
		"mixed_gsm_ids": mixed_gsm_ids,
		"mixed_normal_all_base": _all_prefixed(mixed_normal_ids, "base_"),
		"mixed_gsm_all_gsm": _all_prefixed(mixed_gsm_ids, "gsm_"),
		"weighted_ids": weighted_ids,
		"modifier_weight_ids": modifier_weight_ids,
		"conditional_inactive_ids": conditional_inactive_ids,
		"conditional_active_ids": conditional_active_ids,
		"real_catalog_modifier_inactive_ids": real_catalog_modifier_inactive_ids,
		"real_catalog_modifier_active_ids": real_catalog_modifier_active_ids,
		"equal_weight_ids": equal_weight_ids,
		"history_refill_ids": history_refill_ids,
	}
	print("REWARD_POOL_PROBE=" + JSON.stringify(payload))
	quit()
