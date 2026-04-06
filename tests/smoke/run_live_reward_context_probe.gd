extends SceneTree

const BASE_ONLY_DECK := [
	"strike_01", "strike_02", "defend_01", "strike_03", "defend_02",
	"strike_04", "defend_03", "strike_05", "defend_04", "strike_06"
]

func _extract_ids(offers: Array) -> Array:
	var ids: Array = []
	for offer in offers:
		if not (offer is Dictionary):
			continue
		ids.append(str((offer as Dictionary).get("card_id", "")))
	return ids

func _extract_unlock_keys(runner: Node, offers: Array) -> Array:
	var unlock_keys: Array = []
	for offer in offers:
		if not (offer is Dictionary):
			continue
		var card_id: String = str((offer as Dictionary).get("card_id", ""))
		unlock_keys.append(str(runner.call("_unlock_key_for_card", card_id)))
	return unlock_keys

func _all_unlock_keys_are(unlock_keys: Array, expected: String) -> bool:
	if unlock_keys.is_empty():
		return false
	for unlock_key in unlock_keys:
		if str(unlock_key) != expected:
			return false
	return true

func _capture_offer_profile(runner: Node) -> Dictionary:
	var offers: Array = runner.get("reward_offer")
	var offer_ids: Array = _extract_ids(offers)
	var unlock_keys: Array = _extract_unlock_keys(runner, offers)
	return {
		"offer_ids": offer_ids,
		"unlock_keys": unlock_keys,
		"all_base": _all_unlock_keys_are(unlock_keys, "base_set"),
		"all_gsm": _all_unlock_keys_are(unlock_keys, "gsm_set"),
	}

func _init() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat_slice.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var runner: Node = root_node

	runner.call("reset_battle", 13371337)
	runner.call("_present_reward_checkpoint")
	await process_frame
	var first_profile: Dictionary = _capture_offer_profile(runner)

	runner.call("reset_battle", 13371337)
	runner.set("reward_checkpoint_count", 1)
	runner.call("_present_reward_checkpoint")
	await process_frame
	var second_profile: Dictionary = _capture_offer_profile(runner)

	runner.call("reset_battle", 13371337)
	runner.set("run_master_deck", BASE_ONLY_DECK.duplicate(true))
	runner.set("reward_checkpoint_count", 1)
	runner.call("_present_reward_checkpoint")
	await process_frame
	var base_only_second_profile: Dictionary = _capture_offer_profile(runner)

	var payload: Dictionary = {
		"first_offer_ids": first_profile.get("offer_ids", []),
		"first_offer_unlock_keys": first_profile.get("unlock_keys", []),
		"first_offer_all_base": bool(first_profile.get("all_base", false)),
		"second_offer_ids": second_profile.get("offer_ids", []),
		"second_offer_unlock_keys": second_profile.get("unlock_keys", []),
		"second_offer_all_gsm": bool(second_profile.get("all_gsm", false)),
		"base_only_second_offer_ids": base_only_second_profile.get("offer_ids", []),
		"base_only_second_offer_unlock_keys": base_only_second_profile.get("unlock_keys", []),
		"base_only_second_offer_all_base": bool(base_only_second_profile.get("all_base", false)),
	}
	print("LIVE_REWARD_CONTEXT_PROBE=" + JSON.stringify(payload))
	root_node.queue_free()
	await process_frame
	quit()
