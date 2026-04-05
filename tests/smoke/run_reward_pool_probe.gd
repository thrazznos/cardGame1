extends SceneTree

const REWARD_DRAFT_SCRIPT := preload("res://src/core/reward/reward_draft.gd")
const RSGC_SCRIPT := preload("res://src/core/rng/rsgc.gd")

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

func _init() -> void:
	var draft = REWARD_DRAFT_SCRIPT.new()
	var rng_normal = RSGC_SCRIPT.new()
	rng_normal.bootstrap(1337)

	var history_all_base: Array = ["strike_plus", "strike_precise", "defend_plus", "defend_hold", "scheme_flow"]

	var normal_offer: Dictionary = draft.build_card_offer(rng_normal, "combat_clear_1", history_all_base)
	var normal_ids: Array = _extract_ids(normal_offer.get("offers", []))

	var rng_gsm = RSGC_SCRIPT.new()
	rng_gsm.bootstrap(1337)
	var gsm_offer: Dictionary = draft.build_card_offer(rng_gsm, "gsm_checkpoint_1", history_all_base)
	var gsm_ids: Array = _extract_ids(gsm_offer.get("offers", []))

	var payload: Dictionary = {
		"normal_ids": normal_ids,
		"gsm_ids": gsm_ids,
		"normal_has_gsm": _any_gsm(normal_ids),
		"gsm_all_are_gsm": _all_gsm(gsm_ids),
	}
	print("REWARD_POOL_PROBE=" + JSON.stringify(payload))
	quit()
